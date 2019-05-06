const { assert } = require('chai');
const { Uploader } = require('../../src/uploader');
const aws = require('aws-sdk');

describe('Small file upload @integration test', function() {
  let source = undefined;
  let uploader = undefined;
  let filename = undefined;

  const actualDate = new Date();
  const folder = `${actualDate.getUTCFullYear()}-${`0${actualDate.getUTCMonth()}`.slice(
    -2,
  )}`;

  before(function(done) {
    source = new Buffer.from('key;value\ntest;1\nexample;2\n');
    filename = `${folder}/testfileSmall` + new Date().getTime();
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
      objectName: filename,
      stream: source,
      service: service,
      objectParams: {
        ContentType: 'text/csv',
      },
      debug: true,
    });
    return done();
  });

  return describe(' and When I write a file and finish', function() {
    let data = null;

    before(function(done) {
      this.timeout(parseInt(process.env.TEST_TIMEOUT, 10 || 300000));

      return uploader.send(function(err, returnedData) {
        data = returnedData;
        return done(err);
      });
    });

    it('I have received ETag', () => assert.equal(data.ETag.length, 34));
  });
});
