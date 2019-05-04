/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
const {assert}   = require('chai');
const {Uploader} = require('../../src/uploader');
const aws        = require('aws-sdk');
const async      = require('async');

const getLastFileInBucket = function({accessKey, secretKey, region, bucket}, cb) {
  aws.config.update({
    accessKeyId:     accessKey,
    secretAccessKey: secretKey,
    region:          (region ? region : undefined)
  });

  const client = new aws.S3();
  if (client) {

    const params =
      {Bucket: bucket};

    return client.listObjects(params, function(err, data) {
      if (err) {
        return cb(err);
      }

      if (!__guard__(data != null ? data.Contents : undefined, x => x.length)) {
        cb(new Error(`No files in ${(data != null ? data.Name : undefined)} S3 bucket`));
      }

      let prevDate = 0;
      let newestFile = null;

      return async.each(data.Contents, function(file, callback) {
        const curDate = new Date(file.LastModified);

        if (curDate > prevDate) {
          newestFile = file.Key;
          prevDate = curDate;
        }

        return callback();
      }
      , err => cb(err, newestFile));
    });
  } else {
    return cb(new Error("Error aws client init"));
  }
};

describe('Small file upload @integration test', function() {
  let source = undefined;
  let uploader  = undefined;
  let filename = undefined;

  const actualDate = new Date();
  const folder = `${actualDate.getUTCFullYear()}-${(`0${actualDate.getUTCMonth()}`).slice((-2))}`;


  before(function(done) {
    source = new Buffer("key;value\ntest;1\nexample;2\n");
    filename = `${folder}/testfileSmall` + new Date().getTime();
    uploader = new Uploader({
      accessKey: process.env.AWS_S3_ACCESS_KEY,
      secretKey: process.env.AWS_S3_SECRET_KEY,
      bucket:    process.env.AWS_S3_TEST_BUCKET,
      objectName: filename,
      stream: source,
      objectParams: {
        ContentType: 'text/csv'
      },
      debug: true
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

    return it('List last file in bucket', done =>
      getLastFileInBucket({
        accessKey: process.env.AWS_S3_ACCESS_KEY,
        secretKey: process.env.AWS_S3_SECRET_KEY,
        bucket: process.env.AWS_S3_TEST_BUCKET
      }
        , function(err, file) {
          if (err) { console.error(`Error: ${err}`); }
          assert.equal(file, filename);
          return done(err);
      })
    );
  });
});

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}