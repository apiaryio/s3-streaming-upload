const { assert } = require('chai');
const { Uploader } = require('../../src/uploader');

describe('AWS: 8MB file in parts upload @integration test', () => {
  let buf = '';
  let source = undefined;
  let uploader = undefined;

  before(done => {
    for (let i = 1; i <= 8388608; i++) {
      buf += '0';
    }
    source = new Buffer(buf);

    const actualDate = new Date();
    const folder = `${actualDate.getUTCFullYear()}-${`0${actualDate.getUTCMonth()}`.slice(
      -2,
    )}`;

    uploader = new Uploader({
      accessKey: process.env.AWS_S3_ACCESS_KEY,
      secretKey: process.env.AWS_S3_SECRET_KEY,
      bucket: process.env.AWS_S3_TEST_BUCKET,
      objectName: `${folder}/testfile` + new Date().getTime(),
      stream: source,
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
