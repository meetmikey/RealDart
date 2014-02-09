module.exports = 
  DEFAULT_RESPONSE_MESSAGE: 'internal error'
  DEFAULT_RESPONSE_CODE: 500
  LOG_BREAK: '\n\n\n\n\n\n\n\n'
  DATE_FORMAT: 'yyyy-mm-dd'
  EVENT_TYPE:
    BIRTHDAY: 'birthday'
  PASSWORD_RESET_CODE_LENGTH: 20
  CHECK_WORKERS_INTERVAL: 1000 * 20 #20 seconds
  DEFAULT_WORKER_TIMEOUT: 1000 * 60 * 20 #20 minutes
  SQS_RETRIES: 5
  QUEUE_MAX_MESSAGE_RECEIVE_COUNT: 25
  DEFAULT_RANDOM_ID_LENGTH: 10

  #Milliseconds to wait with one miss.  Will do exponential back-off if many misses.
  #A 'miss' is either an error or 'no message'
  QUEUE_WAIT_TIME_BASE: 10

  #Never wait more than 20 seconds
  QUEUE_MAX_WAIT_TIME: 20*1000

  RADIX_DECIMAL: 10

  service:
    FACEBOOK: 'facebook'
    LINKED_IN: 'linkedIn'
    GOOGLE: 'google'

  message:
    SQS_ALL_WORKERS_DONE: 'All workers done.'

  initAction:
    CONNECT_MONGO: 'connectMongo'
    HANDLE_SQS_WORKERS: 'handleSQSWorkers'