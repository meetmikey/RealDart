Handlebars = require 'handlebars'


Handlebars.registerHelper 'ifCond', (v1, operator, v2, options) ->

  switch operator
    #note: coffeescript forces us to consider == and === to be the same
    when '==' then return ( if v1 is v2 then options.fn(this) else options.inverse(this) )
    when '===' then return ( if v1 is v2 then options.fn(this) else options.inverse(this) )
    when '<' then return ( if v1 < v2 then options.fn(this) else options.inverse(this) )
    when '<=' then return ( if v1 <= v2 then options.fn(this) else options.inverse(this) )
    when '>' then return ( if v1 > v2 then options.fn(this) else options.inverse(this) )
    when '>=' then return ( if v1 >= v2 then options.fn(this) else options.inverse(this) )
    when '&&' then return ( if v1 and v2 then options.fn(this) else options.inverse(this) )
    when '||' then return ( if v1 || v2 then options.fn(this) else options.inverse(this) )
    else return options.inverse(this)

exports.Handlebars = Handlebars