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

    @createNewClient()

    @initiated       = false
    @receivedAllData = false
    @failed          = false
    @partNumber      = 1
    @parts           = []
    @uploadedParts   = {}
    @partSize        = partSize or 5242880 # 5MB
    @currentChunk    = new Buffer 0


    @on 'error', (err) => @failed = true

    @handleStream stream
    process.nextTick => @initiateTransfer()

  createNewClient: ->
    @client = new aws.S3().client

  initiateTransfer: ->
    @client.createMultipartUpload @objectParams, (err, data) =>
      if err
        @emit 'failed', new Error "Cannot initiate transfer"
        @emit 'error', err
        return @cb? err


      @uploadId  = data.UploadId
      @initiated = true

      @emit 'initiated', @uploadId


  handleStream: (stream) ->
    stream.on 'data', (chunk) =>
      if typeof(chunk) is 'string' then chunk = new Buffer chunk, 'utf-8'
      @currentChunk = Buffer.concat [@currentChunk, chunk]

      if @currentChunk.length > @partSize
        @flushPart()

    stream.on 'error', (err) -> @failed = true
    stream.on 'end', =>
      @receivedAllData = true
      if @initiated
        @flushPart()
        @pruneParts()
      else
        @once 'initiated', =>
          @flushPart()
          @pruneParts()


  flushPart: ->
    @parts.push @currentChunk
    @currentChunk = new Buffer 0

    if @initiated
      @uploadChunks()
    else
      @once 'initiated', =>
        @uploadChunks()



  uploadChunks: ->
    async.forEach @parts, (chunk, next) =>
      if chunk.progress or chunk.finished
        next()
      else
        if not chunk.partNumber
          chunk.partNumber = @partNumber
          @partNumber += 1

        chunk.progress = true

        @client.uploadPart
          Body:       chunk
          Bucket:     @objectParams.Bucket
          Key:        @objectName
          PartNumber: chunk.partNumber.toString()
          UploadId:   @uploadId
        , (err, data) =>

          if not chunk.progress
            callbackCalled = true

          chunk.progress = false
          chunk.finished = if err then false else true

          if err
            if not callbackCalled
              if err.code is 'RequestTimeout'
                # create new client as old one died..and try again in next iteration
                @createNewClient()
                # do not propagate err as that whould kill rest of uploads
                next null
              else
                next err
            else
              console.error 'This callback was already called, WTF; chunk', chunk
            @emit 'error', err
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

    finished.reverse()

    for i in finished
      @parts.splice i, 1

    if @receivedAllData
      if @parts.length is 0
        @finishJob()
      else
        setTimeout (=>
          # for race condition about failed parts
          if @parts.length > 0
            @uploadChunks()
          else
            @pruneParts()
        ), 500


  finishJob: ->
    if @finishInProgress then return
    @finishInProgress = true
    @emit 'finishing'
    @client.completeMultipartUpload
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
