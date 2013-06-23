{assert}   = require 'chai'
sinon      = require 'sinon'

{Stream}   = require 'stream'

{Uploader} = require '../src/uploader'

class FakeClient
  createMultipartUpload: (options, cb) ->
    cb null,
      UploadId: 'fakeUploadId'

  completeMultipartUpload: (options, cb) ->
    cb null,
      Location:   'http://example.com/fake/location'
      Bucket:     'fakeBucket'
      Key:        'fakeKey'
      ETag:       'fakeEtag'
      Expiration: 'fakeExpiration'
      VersionId:  'fakeVersionId'

  uploadPart: (options, cb) ->
    cb null, ETag: 'fakeEtag'

describe 'Basic Events', ->
  stream   = undefined
  uploader = undefined

  before ->
    stream = new Stream()

    sinon.stub Uploader.prototype, 'createNewClient', ->
      @client = new FakeClient()

    uploader = new Uploader
      accessKey: 'dummy'
      secretKey: 'dummy'
      stream:    stream
      bucket:    'fakeBucket'

  after ->
    Uploader.prototype.createNewClient.restore()

  describe 'When I write few small bytes and finish', ->
    data = null

    before (done) ->
      uploader.on 'completed', (err, returnedData) ->
        data = returnedData
        done err

      stream.emit 'data', 'Wohoooo'
      stream.emit 'end'

    it 'I have received fake ETag', ->
      assert.equal 'fakeEtag', data.etag



