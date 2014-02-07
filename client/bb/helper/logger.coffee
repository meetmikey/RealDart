class RDHelperLogger

  log: (msg, extra) =>
    @doLog 'log', msg, extra

  warn: (msg, extra) =>
    @doLog 'warn', msg, extra

  error: (msg, extra) =>
    @doLog 'error', msg, extra

  doLog: (type, msg, extra) =>
    unless RD.config.debugMode
      return

    if RD.Helper.utils.isUndefined extra
      console[type] msg
    else
      console[type] msg, extra

RD.Helper.logger = new RDHelperLogger()

window.rdLog = RD.Helper.logger.log
window.rdWarn = RD.Helper.logger.warn
window.rdError = RD.Helper.logger.error