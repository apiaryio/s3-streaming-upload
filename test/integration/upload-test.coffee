{assert}   = require 'chai'
{Uploader} = require '../../src/uploader'

describe 'Small file upload @integration test', ->
  source = undefined
  uploader  = undefined

  before (done) ->
    source = new Buffer "key;value\ntest;1\nexample;2\n"

    uploader = new Uploader
      accessKey: process.env.AWS_S3_ACCESS_KEY
      secretKey: process.env.AWS_S3_SECRET_KEY
      bucket:    process.env.AWS_S3_TEST_BUCKET
      objectName: "testfile" + new Date().getTime()
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
