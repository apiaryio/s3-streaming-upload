## s3-streaming-upload [![Build Status](https://travis-ci.org/apiaryio/s3-streaming-upload.png?branch=master)](https://travis-ci.org/apiaryio/s3-streaming-upload)

[s3-streaming-upload](https://github.com/apiaryio/s3-streaming-upload) is [node.js](http://nodejs.org) library that listens to your [stream](http://nodejs.org/docs/v0.8.9/api/stream.html) and upload its data to Amazon S3 using [MultiPartUpload API](http://docs.amazonwebservices.com/AmazonS3/latest/dev/sdksupportformpu.html).

It is heavily inspired by [knox-mpu](https://github.com/nathanoehlman/knox-mpu), but unlike it, it does not buffer data to disk and is build on top of [official AWS SDK](https://github.com/aws/aws-sdk-js) instead of knox.

### Installation

Installation is done via NPM, by running ```npm install s3-streaming-upload```

### Features

* Super easy to use
* No need to know data size beforehand
* Stream is buffered up to specified size (default 5MBs) and then uploaded to S3
* Segments are not written to disk and memory is freed as soon as possible after upload
* Uploading is asynchronous
* You can react to upload status through events


### Quick example

```javascript

var Uploader = require('s3-streaming-upload').Uploader,
    upload = null,
    stream = require('fs').createReadStream('/etc/resolv.conf');

upload = new Uploader({
  // credentials to access AWS
  accessKey:  process.env.AWS_API_KEY,
  secretKey:  process.env.AWS_SECRET,
  bucket:     process.env.AWS_S3_TRAFFIC_BACKUP_BUCKET,
  objectName: "myUploadedFile",
  stream:     stream
});

upload.on('completed', function (err, res) {
    console.log('upload completed');
});

upload.on('failed', function (err) {
    console.log('upload failed with error', err);
});
````

### Setting up ACL

Pass it in `objectParams` to the `Uploader`:

```javascript

upload = new Uploader({
  // credentials to access AWS
  accessKey:  process.env.AWS_API_KEY,
  secretKey:  process.env.AWS_SECRET,
  bucket:     process.env.AWS_S3_TRAFFIC_BACKUP_BUCKET,
  objectName: "myUploadedFile",
  stream:     stream,
  objectParams: {
    ACL: 'public-read'
  }
});
```
