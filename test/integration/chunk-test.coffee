{assert}   = require 'chai'
{Uploader} = require '../../src/uploader'

describe '8MB file in parts upload @integration test', ->
  buf      = ''
  source   = undefined
  uploader = undefined

  before (done) ->
    for i in [1..8388608]
      buf += "0"
    source = new Buffer buf

    uploader = new Uploader
      accessKey: process.env.AWS_S3_ACCESS_KEY
      secretKey: process.env.AWS_S3_SECRET_KEY
      bucket:    process.env.AWS_S3_TEST_BUCKET
      objectName: "testfile" + new Date().getTime()
      stream:    source
      debug:     false
    done()

  describe ' and when I write a file and finish', ->
    data = null

    before (done) ->
      @timeout parseInt process.env.TEST_TIMEOUT, 10 or 300000

      uploader.send (err, returnedData) ->
        data = returnedData
        done err

    it 'I have received ETag', ->
      assert.equal data.ETag.length, 34
