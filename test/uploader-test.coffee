{assert}   = require 'chai'
{Uploader} = require '../src/uploader'
CoffeeScript = require('coffee-script')
CoffeeScript.register()

describe 'Setup file upload test', ->
  source = undefined
  uploader  = undefined

  objectParams =
    ContentType: 'text/csv'

  before (done) ->
    source = new Buffer "key;value\ntest;1\nexample;2\n"

    uploader = new Uploader
      accessKey: "test-accessKey"
      secretKey: "test-secretKey"
      bucket:    "test-bucket"
      objectName: "testfile1"
      objectParams: objectParams
      stream: source
      debug: true
    done()

  it 'I have set accessKey', ->
    assert.equal uploader.upload.service.config.credentials.accessKeyId, 'test-accessKey'

  it 'I have set bucket', ->
    assert.equal uploader.objectParams.Bucket, 'test-bucket'

  it 'I have set key', ->
    assert.equal uploader.objectParams.Key, 'testfile1'

  it 'I have set ContentType', ->
    assert.equal uploader.objectParams.ContentType, 'text/csv'

  it 'I have set debug', ->
    assert.ok uploader.debug

  describe 'Creating a second uploader', ->
    uploader2 = undefined

    before () =>
      uploader2 = new Uploader
        bucket: 'test-bucket-2'
        stream: new Buffer '...\n'
        objectParams: objectParams

    it 'I have set bucket', ->
      assert.equal uploader2.objectParams.Bucket, 'test-bucket-2'

    it 'I have not unset original bucket', ->
      assert.equal uploader.objectParams.Bucket, 'test-bucket'
