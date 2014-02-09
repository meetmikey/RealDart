#!/bin/sh

#MessageRetentionPeriod: 1209600 # 60 * 60 * 24 * 14 #14 days
#ReceiveMessageWaitTimeSeconds: 20
#VisibilityTimeout: 60 * 10 #10 minutes


aws sqs create-queue --queue-name justinDataImport --attributes MessageRetentionPeriod=1209600,ReceiveMessageWaitTimeSeconds=20,VisibilityTimeout=600
aws sqs create-queue --queue-name "justinDataImport" --attributes {"MessageRetentionPeriod":"1209600","ReceiveMessageWaitTimeSeconds":"20","VisibilityTimeout":"600"}