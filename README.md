## s3-streaming-upload [![s3-streaming-upload](https://github.com/apiaryio/s3-streaming-upload/workflows/s3-streaming-upload%20CI/badge.svg)](https://github.com/apiaryio/s3-streaming-upload/actions?query=workflow%3A%22s3-streaming-upload+CI%22)

[s3-streaming-upload](https://github.com/apiaryio/s3-streaming-upload) is [node.js](http://nodejs.org) library that listens to your [stream](http://nodejs.org/docs/v0.8.9/api/stream.html) and upload its data to Amazon S3 and OCI Bucket Store.

It is heavily inspired by [knox-mpu](https://github.com/nathanoehlman/knox-mpu), but unlike it, it does not buffer data to disk and is build on top of [official AWS SDK](https://github.com/aws/aws-sdk-js) instead of knox.

### Changes

- Version 0.3.2 NodeJS 12+ supported.
- Version 0.3.x Change from Coffee-script to Javascript. NodeJS 6 and 8 supported.

- Version 0.2.x using [ManagedUpload API](http://docs.aws.amazon.com/AWSJavaScriptSDK/latest/AWS/S3/ManagedUpload.html). NodeJS 0.10 and 0.12 supported.

- Version 0.1.x using [MultiPartUpload API](http://docs.amazonwebservices.com/AmazonS3/latest/dev/sdksupportformpu.html). NodeJS 0.8 and 0.10 supported.

### Installation

Installation is done via NPM, by running `npm install s3-streaming-upload`

### Features

- Super easy to use
- No need to know data size beforehand
- Stream is buffered up to specified size (default 5MBs) and then uploaded to S3
- Segments are not written to disk and memory is freed as soon as possible after upload
- Uploading is asynchronous
- You can react to upload status through events

### Quick example

```javascript
var Uploader = require('s3-streaming-upload').Uploader,
  upload = null,
  stream = require('fs').createReadStream('/etc/resolv.conf');

upload = new Uploader({
  // credentials to access AWS
  accessKey: process.env.AWS_S3_ACCESS_KEY,
  secretKey: process.env.AWS_S3_SECRET_KEY,
  bucket: process.env.AWS_S3_TEST_BUCKET,
  objectName: 'myUploadedFile',
  stream: stream,
  debug: true,
});

upload.send(function(err) {
  if (err) {
    console.error('Upload error' + err);
  }
});
```

### Setting up ACL

Pass it in `objectParams` to the `Uploader`:

```javascript
upload = new Uploader({
  // credentials to access AWS
  accessKey: process.env.AWS_API_KEY,
  secretKey: process.env.AWS_SECRET,
  bucket: process.env.AWS_S3_TRAFFIC_BACKUP_BUCKET,
  objectName: 'myUploadedFile',
  stream: stream,
  objectParams: {
    ACL: 'public-read',
  },
});
```

### Example usage with Oracle Cloud (OCI) compatible S3 API

```javascript
region = process.env.OCI_REGION;
tenancy = process.env.OCI_TENANCY;
// define custom service
service = new aws.S3({
  apiVersion: '2006-03-01',
  credentials: {
    accessKeyId: process.env.BUCKET_ACCESS_KEY,
    secretAccessKey: process.env.BUCKET_SECRET_KEY,
  },
  params: { Bucket: process.env.BUCKET_NAME },
  endpoint: `${tenancy}.compat.objectstorage.${region}.oraclecloud.com`,
  region: region,
  signatureVersion: 'v4',
  s3ForcePathStyle: true,
});

uploader = new Uploader({
  accessKey: process.env.BUCKET_ACCESS_KEY,
  secretKey: process.env.BUCKET_SECRET_KEY,
  bucket: process.env.BUCKET_NAME,
  objectName: filename,
  stream: source,
  service: service,
  objectParams: {
    ContentType: 'text/csv',
  },
  debug: true,
});
```
