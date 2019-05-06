const { assert } = require('chai');
const { Uploader } = require('../../src/uploader');
const aws = require('aws-sdk');

describe('OCI: 8MB file in parts upload @integration test', () => {
  let buf = '';
  let source = undefined;
  let uploader = undefined;

  before(done => {
    source = Buffer.alloc(8388608, '0');

    const actualDate = new Date();
    const folder = `${actualDate.getUTCFullYear()}-${`0${actualDate.getUTCMonth()}`.slice(
      -2,
    )}`;

    region = process.env.OCI_REGION;
    tenancy = process.env.OCI_TENANCY;

    service = new aws.S3({
      apiVersion: '2006-03-01',
      credentials: {
        accessKeyId: process.env.AWS_S3_ACCESS_KEY,
        secretAccessKey: process.env.AWS_S3_SECRET_KEY,
      },
      params: { Bucket: process.env.AWS_S3_TEST_BUCKET },
      endpoint: `${tenancy}.compat.objectstorage.${region}.oraclecloud.com`,
      region: region,
      signatureVersion: 'v4',
      s3ForcePathStyle: true,
    });

    uploader = new Uploader({
      accessKey: process.env.AWS_S3_ACCESS_KEY,
      secretKey: process.env.AWS_S3_SECRET_KEY,
      bucket: process.env.AWS_S3_TEST_BUCKET,
      objectName: `${folder}/testfile` + new Date().getTime(),
      stream: source,
      service: service,
      debug: false,
    });
    return done();
  });

  describe(' and when I write a file and finish', () => {
    let data = null;

    before(function(done) {
      this.timeout(parseInt(process.env.TEST_TIMEOUT, 10 || 300000));

      uploader.send(function(err, returnedData) {
        data = returnedData;
        return done(err);
      });
    });

    it('I have received ETag', () => assert.equal(data.ETag.length, 34));
  });
});
