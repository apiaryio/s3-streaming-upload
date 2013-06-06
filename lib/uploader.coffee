{EventEmitter} = require 'events'

async          = require 'async'
aws            = require 'aws-sdk'


class Uploader extends EventEmitter
  #FIXME: 0 records?
  constructor: ({accessKey, secretKey, region, stream, objectName, objectParams, bucket, partSize, maxBufferSize, verbose}, @cb) ->
    super()

    aws.config.update
      accessKeyId:     accessKey
      secretAccessKey: secretKey
      region:          region if region

    @objectName           = objectName
    @objectParams         = objectParams or {}
    @objectParams.Bucket ?= bucket
    @objectParams.Key    ?= objectName

    @maxBufferSize        = maxBufferSize # TODO
    @partSize             = partSize or 5242880 # 5MB
    @verbose             ?= false



    if not @objectParams.Bucket then throw new Error "Bucket must be given"

    @client = new aws.S3().client

    @initiated       = false
    @receivedAllData = false
    @failed          = false
    @partNumber      = 1
    @parts           = []
    @uploadedParts   = {}
    @currentChunk    = new Buffer 0


    @on 'error', (err) => @failed = true

    @setStreamHandlers stream
    process.nextTick => @initiateTransfer()


  initiateTransfer: ->
    @client.createMultipartUpload @objectParams, (err, data) =>
      if err
        @emit 'failed', new Error "Cannot initiate transfer"
        @emit 'error', err
        return @cb? err


      @uploadId  = data.UploadId
      @initiated = true

      @emit 'initiated', @uploadId


  setStreamHandlers: (stream) ->
    stream.on 'data', (chunk) =>
      if typeof(chunk) is 'string' then chunk = new Buffer chunk, 'utf-8'
      @currentChunk = Buffer.concat [@currentChunk, chunk]

      if @currentChunk.length > @partSize
        @flushPart()

    stream.on 'error', (err) -> @failed = true
    stream.on 'close', -> console.error 'closed'
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
        return next()

      currentPartNumber = @partNumber

      chunk.progress = true
      @partNumber++

      @client.uploadPart
        Body:       chunk
        Bucket:     @objectParams.Bucket
        Key:        @objectName
        PartNumber: currentPartNumber.toString()
        UploadId:   @uploadId
      , (err, data) =>
        chunk.progress = false
        chunk.finished = true

        @uploadedParts[currentPartNumber] = data?.ETag

        if err then @emit 'error', err
        @emit 'uploaded', etag: data?.ETag

        next err

    , (err) =>
      if err then console.error 'Upload failed', err
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
        process.stdout.write('W') if @verbose
        setTimeout (=> @pruneParts()), 500


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
