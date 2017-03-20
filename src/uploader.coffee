{EventEmitter} = require 'events'

aws            = require 'aws-sdk'

class Uploader extends EventEmitter
  # Constructor
  constructor: ({accessKey, secretKey, sessionToken, region, endpoint, stream, objectName, objectParams, bucket, partSize, maxBufferSize, waitForPartAttempts, waitTime, service, debug}, @cb) ->
    super()
    aws.config.update
      accessKeyId:     accessKey
      secretAccessKey: secretKey
      sessionToken:    sessionToken
      endpoint:        endpoint if endpoint
      region:          region if region

    @objectName           = objectName
    @objectParams         = objectParams or {}
    @objectParams.Bucket ?= bucket
    @objectParams.Key    ?= objectName
    @objectParams.Body   ?= stream
    @timeout              = 300000
    @debug                = debug or false

    throw new Error "Bucket must be given" unless @objectParams.Bucket

    @upload = new aws.S3.ManagedUpload { partSize: 10 * 1024 * 1024, queueSize: 1, service: service, params: @objectParams }
    @upload.minPartSize = 1024 * 1024 * 5
    @upload.queueSize   = 4
    # Progress event
    @upload.on 'httpUploadProgress', (progress) =>
      console.log "#{progress.loaded} / #{progress.total}" if @debug
  # Send stream
  send: (callback) ->
    @upload.send (err, data) ->
      if err then console.log err, data
      callback err, data

module.exports =
  Uploader: Uploader
