graph = require 'fbgraph'
winston = require('../lib/winstonWrapper').winston

token = 'CAAHdttzClt4BAProzkpBNc4UmjXFhmPQInDCUplqgaZAvu9VtfhNYhnIW9fQ1ZBhosEL1D5omgMg0gUZAS5F0Sv5jZAZA6EZA7kJSIpJErutDHfQx9jAAYyTVDhO6UNS8HDdBKX34GE7aYS38nioUiggeW1e93jaBobUFYqPHF2ckvl4zfNZA95'

graph.setAccessToken token

query = 
  friends: 'SELECT uid, name FROM user WHERE uid IN (SELECT uid2 FROM friend WHERE uid1 = me())'

graph.fql query, (err, res) ->
  winston.doInfo 'got FB query response',
    res: res