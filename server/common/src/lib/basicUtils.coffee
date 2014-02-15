String.prototype.trim = () ->
  this.replace /^\s+|\s+$/g, ''

String.prototype.ltrim = () ->
  this.replace /^\s+/, ''

String.prototype.rtrim = () ->
  this.replace /\s+$/, ''

String.prototype.fulltrim = () ->
  this.replace(/(?:(?:^|\n)\s+|\s+(?:$|\n))/g,'').replace(/\s+/g,' ')