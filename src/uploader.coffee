{EventEmitter} = require 'events'

async          = require 'async'
aws            = require 'aws-sdk'


class Uploader extends EventEmitter
  #FIXME: 0 records?
  constructor: ({accessKey, secretKey, region, stream, objectName, objectParams, bucket, partSize, maxBufferSize}, @cb) ->
    super()
    aws.config.update
      accessKeyId:     accessKey
      secretAccessKey: secretKey
      region:          region if region

    @objectName           = objectName
    @objectParams         = objectParams or {}
    @objectParams.Bucket ?= bucket
    @objectParams.Key    ?= objectName

    @maxBufferSize = maxBufferSize # TODO

    if not @objectParams.Bucket then throw new Error "Bucket must be given"

    @initiated       = false
    @initializing    = false
    @failed          = false
    @partNumber      = 1
    @parts           = []
    @uploadedParts   = {}
    @partSize        = partSize or 5242880 # 5MB
    @currentChunk    = new Buffer 0


    @on 'error', (err) => @failed = true

    @handleStream stream
    #process.nextTick => @initiateTransfer()

    @uploadTimer = setInterval ()=>
      #because of timeouts - otherwise every tick is "occupied" by stream operations
      @uploadChunks()
    , 5000

  getNewClient: ->
    new aws.S3().client

  initiateTransfer: ->
    @initializing = true
    @getNewClient().createMultipartUpload @objectParams, (err, data) =>
      @initializing = false

      if err
        @emit 'failed', new Error "Cannot initiate transfer"
        @emit 'error', err
        return @cb? err


      @uploadId  = data.UploadId
      @initiated = true

      @emit 'initiated', @uploadId


  handleStream: (stream) ->
    stream.on 'data', (chunk) =>
      if typeof(chunk) is 'string'
        chunk = new Buffer chunk, 'utf-8'

      @currentChunk = Buffer.concat [@currentChunk, chunk]

      if @currentChunk.length > @partSize
        @flushPart()

    stream.on 'error', (err) -> @failed = true
    stream.on 'end', =>
      if @initiated
        @flushPart()
        @finishUploads()
      else
        @initiateTransfer()
        @once 'initiated', =>
          @flushPart()
          @finishUploads()

  finishUploads: ->
    if @uploadTimer
      clearInterval @uploadTimer

    @pruneTimer = setInterval (=>
      if @parts.length is 0
        @finishJob()
      else
        # for race condition about failed parts
        console.error @parts.length
        if @parts.length > 0
          @uploadChunks()
        else
          @pruneParts()
      ), 5000

  flushPart: ->
    @parts.push @currentChunk
    @currentChunk = new Buffer 0
    @uploadChunks()



  uploadChunks: ->
    if not @initiated
      if not @initializing
        @initiateTransfer()

      @once 'initiated', =>
        @uploadChunks()
      return

    if not @parts?.length
      return

    partsToProcess = []

    for chunk in @parts
      if not (chunk.progress or chunk.finished)
        partsToProcess.push chunk

    async.forEach partsToProcess, (chunk, next) =>
      if chunk.progress or chunk.finished
        next()
      else
        if not chunk.partNumber
          chunk.partNumber = @partNumber
          @partNumber += 1

        chunk.progress = true
        chunk.client ?= @getNewClient()

        chunk.client.uploadPart
          Body:       chunk
          Bucket:     @objectParams.Bucket
          Key:        @objectName
          PartNumber: chunk.partNumber.toString()
          UploadId:   @uploadId
        , (err, data) =>
          chunk.progress = false
          chunk.finished = if err then false else true

          if err
            if err.code is 'RequestTimeout'
              # new client will be created in next run
              chunk.client = undefined
              # do not propagate err as that whould kill rest of uploads
              return next null
            else
              @emit 'error', err
              return next err

          else
            @uploadedParts[chunk.partNumber] = data.ETag
            @emit 'uploaded', etag: data.ETag
            return next()

    , (err) =>
      if err
        console.error 'Cannot upload chunks', err
      @pruneParts()

  pruneParts: ->
    #TODO: AM time algorithm, do w/o recursion
    i = 0
    finished = []
    for el in @parts
      if el.finished
        finished.push i
      i++

    finished.reverse()

    for i in finished
      @parts.splice i, 1




  finishJob: ->
    if @finishInProgress
      return

    if @pruneTimer
      clearInterval @pruneTimer

    @finishInProgress = true

    @emit 'finishing'
    @getNewClient().completeMultipartUpload
      UploadId: @uploadId
      Bucket:   @objectParams.Bucket
      Key:      @objectParams.Key
      MultipartUpload: Parts: ({'ETag': etag, 'PartNumber': parseInt(partNumber, 10)} for partNumber, etag of @uploadedParts)
    , (err, data) =>
      @emit 'finished', data
      if err
        @emit 'error', err
        @failed = true

      if @failed
        return @emit 'failed', err
      @emit 'completed', err, location: data.Location, bucket: data.Bucket, key: data.Key, etag: data.ETag, expiration: data.Expiration, versionId: data.VersionId

module.exports =
  Uploader: Uploader
