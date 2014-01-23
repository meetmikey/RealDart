# use Grunt.js in future for more robust asset build process
# eg. minification, compilation, etc
@javascript 'scripts', ->
  @options
    build: './build/js'

  @coffeescript './src', output: './app'
  @coffeescript './test/coffee', output: './test/js'
  @coffeescript './test/coffee/spec', output: './test/js/spec'
