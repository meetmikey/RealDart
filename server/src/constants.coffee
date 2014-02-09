module.exports = 
  DEFAULT_RESPONSE_MESSAGE: 'internal error'
  DEFAULT_RESPONSE_CODE: 500
  LOG_BREAK: '\n\n\n\n\n\n\n\n'
  DATE_FORMAT: 'yyyy-mm-dd'
  EVENT_TYPE:
    BIRTHDAY: 'birthday'
  PASSWORD_RESET_CODE_LENGTH: 20
  CHECK_WORKERS_INTERVAL: 20*1000
  DEFAULT_WORKER_TIMEOUT: 20*60*1000
  SQS_RETRIES: 5
  QUEUE_MAX_MESSAGE_RECEIVE_COUNT: 25

  #Milliseconds to wait with one miss.  Will do exponential back-off if many misses.
  #A 'miss' is either an error or 'no message'
  QUEUE_WAIT_TIME_BASE: 10

  #Never wait more than 20 seconds
  QUEUE_MAX_WAIT_TIME: 20*1000

  RADIX_DECIMAL: 10

  service:
    FACEBOOK: 'facebook'
    LINKED_IN: 'linkedIn'
    GMAIL: 'gmail'

  message:
    SQS_ALL_WORKERS_DONE: 'All workers done.'