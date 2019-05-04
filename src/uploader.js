const {EventEmitter} = require ('events');

const aws = require ('aws-sdk');

class Uploader extends EventEmitter {
  // Constructor
  constructor (
    {
      accessKey,
      secretKey,
      sessionToken,
      region,
      stream,
      objectName,
      objectParams,
      bucket,
      partSize,
      maxBufferSize,
      waitForPartAttempts,
      waitTime,
      service,
      debug,
    },
    cb
  ) {
    super ();
    this.cb = cb;
    aws.config.update ({
      accessKeyId: accessKey,
      secretAccessKey: secretKey,
      sessionToken,
      region: region ? region : undefined,
    });

    const params = {
      Bucket: bucket,
      Key: objectName,
      Body: stream,
    };

    for (let k in objectParams || {}) {
      if (!params[k]) {
        params[k] = objectParams[k];
      }
    }

    this.objectName = objectName;
    this.objectParams = params;
    this.timeout = 300000;
    this.debug = debug || false;

    if (!this.objectParams.Bucket) {
      throw new Error ('Bucket must be given');
    }

    this.upload = new aws.S3.ManagedUpload ({
      partSize: 10 * 1024 * 1024,
      queueSize: 1,
      service,
      params,
    });
    this.upload.minPartSize = 1024 * 1024 * 5;
    this.upload.queueSize = 4;
    // Progress event
    this.upload.on ('httpUploadProgress', progress => {
      if (this.debug) {
        return console.log (`${progress.loaded} / ${progress.total}`);
      }
    });
  }
  // Send stream
  send (callback) {
    return this.upload.send (function (err, data) {
      if (err) {
        console.log (err, data);
      }
      return callback (err, data);
    });
  }
}

module.exports = {Uploader};
