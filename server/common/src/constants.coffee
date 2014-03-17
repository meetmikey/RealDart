module.exports = 
  DEFAULT_RESPONSE_MESSAGE: 'internal error'
  DEFAULT_RESPONSE_CODE: 500
  LOG_BREAK: '\n\n\n\n\n\n\n\n'
  DATE_FORMAT: 'yyyy-mm-dd'
  EVENT_TYPE:
    BIRTHDAY: 'birthday'
  PASSWORD_RESET_CODE_LENGTH: 20
  
  DEFAULT_RANDOM_ID_LENGTH: 10
  MAX_STREAM_TO_BUFFER: 31457280
  DEFAULT_NUM_REDIRECTS_TO_FOLLOW: 4
  DEFAULT_WEB_GET_TIMEOUT: 30000
  RESPONSE_MAX_WAIT_MS: 5000
  MONGO_ERROR_CODE_DUPLICATE: 11000
  DEFAULT_API_CALL_ATTEMPTS: 3
  DEFAULT_WEB_GET_ATTEMPTS: 3
  HEADER_DOWNLOAD_BATCH_SIZE: 1000
  ADD_EMAIL_TOUCHES_EMAIL_BATCH_SIZE: 1000
  IMPORT_CONTACT_IMAGES_ASYNC_LIMIT: 10

  S3_DEFAULT_LINK_EXPIRE_MINUTES: 30

  sqs:
    #Milliseconds to wait with one miss.  Will do exponential back-off if many misses.
    #A 'miss' is either an error or 'no message'
    WAIT_TIME_BASE_MS: 10
    MAX_WAIT_TIME_MS: 1000 * 5 # Never wait more than 5 seconds
    MAX_MESSAGE_RECEIVE_COUNT: 25
    NUM_RETRIES: 5
    CHECK_WORKERS_INTERVAL: 1000 * 20 #20 seconds
    DEFAULT_WORKER_TIMEOUT: 1000 * 60 * 20 #20 minutes
    DEFAULT_MAX_WORKERS_PER_QUEUE: 1
    MAX_RECEIVE_MESSAGES: 10 # This is a AWS limit on the number of messages that can be received in one call.


  RADIX_DECIMAL: 10

  gmail:
    topLevelBoxName:
      GMAIL: '[Gmail]'
      GOOGLE_MAIL: '[Google Mail]'
    mailBoxType:
      SENT: 'sent'
    ACCESS_TOKEN_UPDATE_TIME_BUFFER: 1000 * 60 * 10  #10 minutes

  service:
    FACEBOOK: 'facebook'
    LINKED_IN: 'linkedIn'
    GOOGLE: 'google'

  contactSource:
    FACEBOOK: 'facebook'
    LINKED_IN: 'linkedIn'
    GOOGLE: 'google'
    EMAIL_HEADER: 'emailHeader'
    
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
    web:
      FOUR_OH_FOUR: '404'

  lock:
    BASE_WAIT_TIME_MS: 10
    MAX_WAIT_TIME_MS: 1000 * 60 * 1 #1 minute
    EXPIRE_TIME_SECONDS: 60 * 60 * 1 #1 hour
    keyPrefix:
      contacts: 'contacts-'

  touch:
    type:
      EMAIL: 'email'


  #  NAME PARSING CONSTANTS
  ##################################################

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

  EMAIL_CONTACT_BLACKLIST: [
    'support@',
    'notification@',
    'notifications@',
    'noreply@',
    'no-reply@',
    'do-not-reply@',
    'mailer-daemon@',
    'alerts@',
    'alert@',
    'reservations@',
    'reservation@',
    'confirmation@',
    'contact@',
    'craigslist'
  ]


  US_STATE_CODES : {
    'WA':'Washington',
    'DE':'Delaware',
    'DC':'District Of Columbia',
    'WI':'Wisconsin',
    'WV':'West Virginia',
    'HI':'Hawaii',
    'FL':'Florida',
    'WY':'Wyoming',
    'NH':'New Hampshire',
    'NJ':'New Jersey',
    'NM':'New Mexico',
    'TX':'Texas',
    'LA':'Louisiana',
    'NC':'North Carolina',
    'ND':'North Dakota',
    'NE':'Nebraska',
    'TN':'Tennessee',
    'NY':'New York',
    'PA':'Pennsylvania',
    'AK':'Alaska',
    'NV':'Nevada',
    'VA':'Virginia',
    'CO':'Colorado',
    'CA':'California',
    'AL':'Alabama',
    'AR':'Arkansas',
    'VT':'Vermont',
    'IL':'Illinois',
    'GA':'Georgia',
    'IN':'Indiana',
    'IA':'Iowa',
    'MA':'Massachusetts',
    'AZ':'Arizona',
    'ID':'Idaho',
    'CT':'Connecticut',
    'ME':'Maine',
    'MD':'Maryland',
    'OK':'Oklahoma',
    'OH':'Ohio',
    'UT':'Utah',
    'MO':'Missouri',
    'MN':'Minnesota',
    'MI':'Michigan',
    'RI':'Rhode Island',
    'KS':'Kansas',
    'MT':'Montana',
    'MS':'Mississippi',
    'SC':'South Carolina',
    'KY':'Kentucky',
    'OR':'Oregon',
    'SD':'South Dakota'
  }

  US_STATE_CODES_INV : {
    "Mississippi": "MS",
    "Georgia": "GA",
    "Wyoming": "WY",
    "Minnesota": "MN",
    "Illinois": "IL",
    "District Of Columbia": "DC",
    "Arkansas": "AR",
    "New Mexico": "NM",
    "Ohio": "OH",
    "Indiana": "IN",
    "Maryland": "MD",
    "Louisiana": "LA",
    "Texas": "TX",
    "Arizona": "AZ",
    "Wisconsin": "WI",
    "Michigan": "MI",
    "Kansas": "KS",
    "Utah": "UT",
    "Virginia": "VA",
    "Oregon": "OR",
    "Connecticut": "CT",
    "New York": "NY",
    "New Hampshire": "NH",
    "Massachusetts": "MA",
    "West Virginia": "WV",
    "South Carolina": "SC",
    "California": "CA",
    "Oklahoma": "OK",
    "Vermont": "VT",
    "Delaware": "DE",
    "North Dakota": "ND",
    "Pennsylvania": "PA",
    "Florida": "FL",
    "Hawaii": "HI",
    "Kentucky": "KY",
    "Alaska": "AK",
    "Nebraska": "NE",
    "Missouri": "MO",
    "Iowa": "IA",
    "Alabama": "AL",
    "Rhode Island": "RI",
    "South Dakota": "SD",
    "Colorado": "CO",
    "Idaho": "ID",
    "New Jersey": "NJ",
    "Washington": "WA",
    "North Carolina": "NC",
    "Tennessee": "TN",
    "Montana": "MT",
    "Nevada": "NV",
    "Maine": "ME"
  }
