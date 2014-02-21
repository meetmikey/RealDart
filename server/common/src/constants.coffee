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
  MAX_STREAM_TO_BUFFER: 31457280
  DEFAULT_NUM_REDIRECTS_TO_FOLLOW: 4
  DEFAULT_WEB_GET_TIMEOUT: 30000
  RESPONSE_MAX_WAIT_MS: 5000
  MONGO_ERROR_CODE_DUPLICATE: 11000

  #Milliseconds to wait with one miss.  Will do exponential back-off if many misses.
  #A 'miss' is either an error or 'no message'
  QUEUE_WAIT_TIME_BASE: 10

  #Never wait more than 20 seconds
  QUEUE_MAX_WAIT_TIME: 20*1000

  RADIX_DECIMAL: 10

  gmail:
    topLevelBoxName:
      GMAIL: '[Gmail]'
      GOOGLE_MAIL: '[Google Mail]'
    mailBoxType:
      SENT: 'sent'

  service:
    FACEBOOK: 'facebook'
    LINKED_IN: 'linkedIn'
    GOOGLE: 'google'
    SENT_MAIL_TOUCH: 'sentMailTouch' #This is here because 'services' double as possible contact sources,
                                     # one of which is finding the email in the sent mail


  message:
    SQS_ALL_WORKERS_DONE: 'All workers done.'

  initAction:
    CONNECT_MONGO: 'connectMongo'
    HANDLE_SQS_WORKERS: 'handleSQSWorkers'

  errorType:
    imap:
      DOMAIN_ERROR: 'domainError'
      NO_BOX_TO_OPEN: 'noBoxToOpen'
      MAIL_BOX_DOES_NOT_EXIST: 'mailBoxDoesNotExist'

  # Modified version of http://notes.ericwillis.com/2009/11/common-name-prefixes-titles-and-honorifics/
  # NOTE: must be lower case, and exclude any periods ("."s)
  NAME_PREFIXES: [
    'adm'
    'atty'
    'br'
    'coach'
    'd'
    'dr'
    'fr'
    'gov'
    'hon'
    'm'
    'master'
    'miss'
    'mr'
    'mrs'
    'ms'
    'msgr'
    'ofc'
    'pres'
    'prof'
    'rabbi'
    'rep'
    'rev'
    'reverend'
    'sen'
    'sr'
  ]

  # NOTE: must be lower case, and exclude any periods ("."s)
  NAME_SUFFIXES: [
    '1'
    '1st'
    '2'
    '2nd'
    '3'
    '3rd'
    '4'
    '4th'
    '5'
    '5th'
    '6'
    '6th'
    'ab'
    'ba'
    'be'
    'bfa'
    'bs'
    'bsc'
    'btech'
    'dc'
    'do'
    'dphil'
    'engd'
    'esq'
    'esquire'
    'i'
    'ii'
    'iii'
    'iv'
    'jd'
    'junior'
    'jr'
    'llb'
    'lld'
    'llm'
    'ma'
    'ms'
    'mba'
    'md'
    'meng'
    'mfa'
    'mla'
    'msc'
    'pharmd'
    'phd'
    'senior'
    'sr'
    'v'
    'vi'
  ]

  # NOTE: must be lower case
  LAST_NAME_PREFIXES: [
    'el'
  ]