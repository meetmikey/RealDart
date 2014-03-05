# RealDart
========

## Local setup
========

### Requirements
- node
- mongo
- grunt

### Environment
- Add local environment variables to your ~/.bashrc file
  - *export REAL_DART_HOME='/home/jdurack/source/RealDart'*
  - *export AWS_PREFIX='justin'*
- *cd* to server/web/app and create a symlink to /public with *ln -s ../../../public/ public*

### Building
- Open a terminal and go to each of the following directores, and run *npm install*, then *grunt*.  Just leave grunt running to continuosly build changes.
  - client
  - server/common
  - server/tools
  - server/web
  - server/worker

### AWS
- Add SQS queues for each of the queues listed in *serverCommon/conf.queue*.  They should be named your $AWS_PREFIX + the camelCase queue name (e.g. justinDataImport)
- Add an s3 bucket named $AWS_PREFIX + '-realdart'
  - Then create a folder for each of the folders listed in *serverCommon/conf.aws.s3.folder*

### Run it
- Web: *cd* to /server and run *node web/app/app.js*
- Worker: *cd* to /server and run *node worker/app/app.js*
- NOTE: nodemon is a nice way to not have to restart with every change
- Go to *http://local.realdart.com:3000/*