# RealDart
========

## Local setup
========

### Requirements
- node
- mongo
- grunt

### Conf
- Copy conf_template.coffee to conf.coffee. Fill in with appropriate API keys and secrets for each service

### Building
- Open a terminal and go to each of the following directores, and run *npm install*, then *grunt*.  Just leave grunt running to continuosly build changes.
  - client
  - server/common
  - server/tools
  - server/web
  - server/worker

### AWS
- Add SQS queues for each of the queues listed in *serverCommon/conf.queue*.  They should be named your $AWS_PREFIX + the camelCase queue name (e.g. 'justinDataImport').  Give each queue the following configuration:
  - Default visibility timeout: 5 minutes
  - Message retention period: 14 days
  - Maximum message size: 256KB (the default)
  - Delivery delay: 0 seconds (the default)
  - Receive message wait time: 0 seconds  (the new sqsUtils does not use long polling anymore)
  - set the redrive policy to use "$AWS_PREFIX + Graveyard", with Maximum Receives of 20.
- Add an s3 bucket named $AWS_PREFIX + '-realdart' (e.g. 'justin-realdart')
  - Then create a folder for each of the folders listed in *serverCommon/conf.aws.s3.folder*

### Environment
- Add local environment variables to your ~/.bashrc file
  - *export REAL_DART_HOME='/home/jdurack/source/RealDart'*
  - *export AWS_PREFIX='justin'*
- *cd* to server/web/app and create a symlink to /public with *ln -s ../../../public/ public*
- Add *127.0.0.1 localhost local.realdart.com* to your */etc/hosts* file

### Run it
- Web: *cd* to /server and run *node web/app/app.js*
- Worker: *cd* to /server and run *node worker/app/app.js*
- NOTE: nodemon is a nice way to not have to restart with every change
- Go to *http://local.realdart.com:3000/*

