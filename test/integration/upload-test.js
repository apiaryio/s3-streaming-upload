/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
const { assert } = require('chai');
const aws = require('aws-sdk');
const async = require('async');
const { Uploader } = require('../../src');

const getLastFileInBucket = ({ accessKey, secretKey, region, bucket }, cb) => {
  aws.config.update({
    accessKeyId: accessKey,
    secretAccessKey: secretKey,
    region: region || undefined,
  });

  const client = new aws.S3();
  if (client) {
    const params = { Bucket: bucket };

    client.listObjects(params, (err, data) => {
      if (err) {
        cb(err);
      }

      if (!data || !data.Contents || !data.Contents.length) {
        cb(new Error(`No files in ${data ? data.Name : undefined} S3 bucket`));
      }

      let prevDate = 0;
      let newestFile = null;

      async.each(
        data.Contents,
        (file, callback) => {
          const curDate = new Date(file.LastModified);

          if (curDate > prevDate) {
            newestFile = file.Key;
            prevDate = curDate;
          }

          callback();
        },
        asyncErr => cb(asyncErr, newestFile)
      );
    });
  } else {
    cb(new Error('Error aws client init'));
  }
};

describe('AWS: Small file upload @integration test', () => {
  let source;
  let uploader;
  let filename;

  const actualDate = new Date();
  const folder = `${actualDate.getUTCFullYear()}-${`0${actualDate.getUTCMonth()}`.slice(-2)}`;

  before((done) => {
    source = Buffer.from('key;value\ntest;1\nexample;2\n');
    filename = `${folder}/testfileSmall${new Date().getTime()}`;
    uploader = new Uploader({
      accessKey: process.env.AWS_S3_ACCESS_KEY,
      secretKey: process.env.AWS_S3_SECRET_KEY,
      bucket: process.env.AWS_S3_TEST_BUCKET,
      objectName: filename,
      stream: source,
      objectParams: {
        ContentType: 'text/csv',
      },
      debug: true,
    });
    done();
  });

  describe(' and When I write a file and finish', () => {
    let data = null;

    before(function send(done) {
      this.timeout(parseInt(process.env.TEST_TIMEOUT, 10) || 300000);

      uploader.send((err, returnedData) => {
        data = returnedData;
        done(err);
      });
    });

    it('I have received ETag', () => assert.equal(data.ETag.length, 34));

    it('List last file in bucket', done => getLastFileInBucket(
      {
        accessKey: process.env.AWS_S3_ACCESS_KEY,
        secretKey: process.env.AWS_S3_SECRET_KEY,
        bucket: process.env.AWS_S3_TEST_BUCKET,
      },
      (err, file) => {
        if (err) {
          console.error(`Error: ${err}`);
        }
        assert.equal(file, filename);
        done(err);
      }
    ));
  });
});
