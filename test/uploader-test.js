const { assert } = require('chai');
const { Uploader } = require('../src');

describe('Setup file upload test', function() {
  let source = undefined;
  let uploader = undefined;

  const objectParams = { ContentType: 'text/csv' };

  before(function(done) {
    source = Buffer.from('key;value\ntest;1\nexample;2\n');

    uploader = new Uploader({
      accessKey: 'test-accessKey',
      secretKey: 'test-secretKey',
      bucket: 'test-bucket',
      objectName: 'testfile1',
      objectParams,
      stream: source,
      debug: true,
    });
    return done();
  });

  it('I have set accessKey', () =>
    assert.equal(
      uploader.upload.service.config.credentials.accessKeyId,
      'test-accessKey',
    ));

  it('I have set bucket', () =>
    assert.equal(uploader.objectParams.Bucket, 'test-bucket'));

  it('I have set key', () =>
    assert.equal(uploader.objectParams.Key, 'testfile1'));

  it('I have set ContentType', () =>
    assert.equal(uploader.objectParams.ContentType, 'text/csv'));

  it('I have set debug', () => assert.ok(uploader.debug));

  describe('Creating a second uploader', function() {
    let uploader2 = undefined;

    before(() => {
      return (uploader2 = new Uploader({
        bucket: 'test-bucket-2',
        stream: Buffer.from('...\n'),
        objectParams,
      }));
    });

    it('I have set bucket', () =>
      assert.equal(uploader2.objectParams.Bucket, 'test-bucket-2'));

    it('I have not unset original bucket', () =>
      assert.equal(uploader.objectParams.Bucket, 'test-bucket'));
  });
});
