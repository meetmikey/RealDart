module.exports =
  server:
    host: 'local.realdart.com'
    listenPort: 3000
    useSSL: false
  session:
    jwtSecret: 'cc126792f0ad3f48ac7121fbec1a9516'
    #expireTimeMinutes: 60 * 24 * 10 #10 days
    expireTimeMinutes: 60 * 24 * .5 #TEMP: half a day
  express:
    secret: '58afcd73e04fb42b602e5d414f9081f63e013975'