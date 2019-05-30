const { assert } = require('chai');
const { Uploader } = require('../src');

describe('Setup file upload test', () => {
  let source;
  let uploader;

  const objectParams = { ContentType: 'text/csv' };

  before(() => {
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
  });

  it('Should have set accessKey', () => assert.equal(uploader.upload.service.config.credentials.accessKeyId, 'test-accessKey'));

  it('Should have set bucket', () => assert.equal(uploader.objectParams.Bucket, 'test-bucket'));

  it('Should have set key', () => assert.equal(uploader.objectParams.Key, 'testfile1'));

  it('Should have set ContentType', () => assert.equal(uploader.objectParams.ContentType, 'text/csv'));

  it('Should have set debug', () => assert.ok(uploader.debug));

  it('Should not create custom service', () => assert.isUndefined(uploader.service));

  describe('Creating a second uploader', () => {
    let uploader2;

    before(() => {
      uploader2 = new Uploader({
        bucket: 'test-bucket-2',
        stream: Buffer.from('...\n'),
        objectParams,
      });
    });

    it('Should have set bucket', () => assert.equal(uploader2.objectParams.Bucket, 'test-bucket-2'));

    it('Should have not unset original bucket', () => assert.equal(uploader.objectParams.Bucket, 'test-bucket'));
  });
});
