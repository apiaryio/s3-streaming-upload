{assert}   = require 'chai'
{Stream}   = require 'stream'
fs         = require 'fs'
{Uploader} = require '../../src/uploader'

process.env.TEST_TIMEOUT ?= 300000


describe 'Small file in parts upload @integration test', ->
  stream   = undefined
  uploader = undefined

  before (done) ->
    stream = fs.createReadStream "#{__dirname}/../fixtures/small-file.txt"
    uploader = new Uploader
      accessKey: process.env.AWS_S3_ACCESS_KEY
      secretKey: process.env.AWS_S3_SECRET_KEY
      bucket:    process.env.AWS_S3_TEST_BUCKET
      objectName: "testfile" + new Date().getTime()
      stream:    stream
    done()

  describe ' and set partSize to 6 and when I write file and finish', ->
    data = null

    before (done) ->
      @timeout process.env.TEST_TIMEOUT
      uploader.partSize = 6

      uploader.on 'completed', (err, returnedData) ->
        data = returnedData
        done err

    it 'I have received ETag', ->
      assert.equal data.etag.length, 36
