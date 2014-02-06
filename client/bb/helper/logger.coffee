class RealDartHelperLogger

  log: (msg, extra) =>
    @doLog 'log', msg, extra

  error: (msg, extra) =>
    @doLog 'error', msg, extra

  doLog: (type, msg, extra) =>
    unless RealDart.Config.enableLogging
      return

    if RealDart.Helper.Utils.isUndefined extra
      console[type] msg
    else
      console[type] msg, extra

RealDart.Helper.Logger = new RealDartHelperLogger()

window.rdLog = RealDart.Helper.Logger.log
window.rdError = RealDart.Helper.Logger.error