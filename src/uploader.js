/*
 * decaffeinate suggestions:
 * DS001: Remove Babel/TypeScript constructor workaround
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
const {EventEmitter} = require('events');

const aws            = require('aws-sdk');

class Uploader extends EventEmitter {
  // Constructor
  constructor({accessKey, secretKey, sessionToken, region, stream, objectName, objectParams, bucket, partSize, maxBufferSize, waitForPartAttempts, waitTime, service, debug}, cb) {
    {
      // Hack: trick Babel/TypeScript into allowing this before super.
      if (false) { super(); }
      let thisFn = (() => { return this; }).toString();
      let thisName = thisFn.match(/return (?:_assertThisInitialized\()*(\w+)\)*;/)[1];
      eval(`${thisName} = this;`);
    }
    this.cb = cb;
    super();
    aws.config.update({
      accessKeyId:     accessKey,
      secretAccessKey: secretKey,
      sessionToken,
      region:          (region ? region : undefined)
    });

    const params = {
      Bucket: bucket,
      Key: objectName,
      Body: stream
    };

    for (let k in objectParams || {}) {
      if (!params[k]) { params[k] = objectParams[k]; }
    }

    this.objectName           = objectName;
    this.objectParams         = params;
    this.timeout              = 300000;
    this.debug                = debug || false;

    if (!this.objectParams.Bucket) { throw new Error("Bucket must be given"); }

    this.upload = new aws.S3.ManagedUpload({ partSize: 10 * 1024 * 1024, queueSize: 1, service, params });
    this.upload.minPartSize = 1024 * 1024 * 5;
    this.upload.queueSize   = 4;
    // Progress event
    this.upload.on('httpUploadProgress', progress => {
      if (this.debug) { return console.log(`${progress.loaded} / ${progress.total}`); }
    });
  }
  // Send stream
  send(callback) {
    return this.upload.send(function(err, data) {
      if (err) { console.log(err, data); }
      return callback(err, data);
    });
  }
}

module.exports =
  {Uploader};
