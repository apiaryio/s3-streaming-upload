{assert}   = require 'chai'
{Uploader} = require '../../src/uploader'
aws        = require 'aws-sdk'
async      = require 'async'

getLastFileInBucket = ({accessKey, secretKey, region, bucket}, cb) ->
  aws.config.update
    accessKeyId: accessKey
    secretAccessKey: secretKey
    region: region if region

  client = new aws.S3()
  if client

    params =
      Bucket: bucket

    client.listObjects params, (err, data) ->
      if err
        return cb err

      if not data?.Contents?.length
        cb new Error "No files in #{data?.Name} S3 bucket"

      prevDate = 0
      newestFile = null

      async.each data.Contents, (file, callback) ->
        curDate = new Date(file.LastModified)

        if (curDate > prevDate)
          newestFile = file.Key
          prevDate = curDate

        callback()
      , (err) ->
        cb err, newestFile
  else
    cb new Error("Error aws client init")

describe 'Small file upload @integration test', ->
  source = undefined
  uploader  = undefined
  filename = undefined

  actualDate = new Date()
  folder = "#{actualDate.getUTCFullYear()}-#{('0' + actualDate.getUTCMonth()).slice (-2)}"


  before (done) ->
    filename = "#{folder}/testfileSmall" + new Date().getTime()
    source = new Buffer 'key;value\ntest;1\nexample;2\n'

    uploader = new Uploader
      accessKey: process.env.AWS_S3_ACCESS_KEY
      secretKey: process.env.AWS_S3_SECRET_KEY
      bucket: process.env.AWS_S3_TEST_BUCKET
      objectName: filename
      stream: source
      objectParams:
        ContentType: 'text/csv'
      debug: true
    done()

  describe ' and When I write a file and finish', ->
    data = null

    before (done) ->
      @timeout parseInt process.env.TEST_TIMEOUT, 10 or 300000

      uploader.send (err, returnedData) ->
        data = returnedData
        done err

    it 'I have received ETag', ->
      assert.equal data.ETag.length, 34

    it 'List last file in bucket', (done) ->
      getLastFileInBucket
        accessKey: process.env.AWS_S3_ACCESS_KEY
        secretKey: process.env.AWS_S3_SECRET_KEY
        bucket: process.env.AWS_S3_TEST_BUCKET
        , (err, file) ->
          if err then console.error "Error: #{err}"
          assert.equal file, filename
          done err
