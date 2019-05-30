const { EventEmitter } = require('events');

const aws = require('aws-sdk');

class Uploader extends EventEmitter {
  // Constructor
  constructor({
    accessKey,
    secretKey,
    sessionToken,
    region,
    stream,
    objectName,
    objectParams,
    bucket,
    partSize,
    service,
    debug,
  }, cb) {
    super();
    this.cb = cb;
    aws.config.update({
      accessKeyId: accessKey,
      secretAccessKey: secretKey,
      sessionToken,
      region: region || undefined,
    });

    const params = {
      Bucket: bucket,
      Key: objectName,
      Body: stream,
    };

    for (const k in objectParams || {}) {
      if (!params[k]) {
        params[k] = objectParams[k];
      }
    }

    this.objectName = objectName;
    this.objectParams = params;
    this.timeout = 300000;
    this.debug = debug || false;

    if (!this.objectParams.Bucket) {
      throw new Error('Bucket must be given');
    }

    this.upload = new aws.S3.ManagedUpload({
      partSize: partSize || 10 * 1024 * 1024,
      queueSize: 4,
      service,
      params,
    });
    // Progress event
    this.upload.on('httpUploadProgress', (progress) => {
      if (this.debug) {
        console.log(`${progress.loaded} / ${progress.total}`);
      }
    });
  }

  // Send stream
  send(callback) {
    this.upload.send((err, data) => {
      if (err) {
        console.log(err, data);
      }
      callback(err, data);
    });
  }
}

module.exports = { Uploader };
