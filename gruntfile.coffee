module.exports = (grunt) ->

  # Project configuration.
  grunt.initConfig
    pkg: grunt.file.readJSON 'package.json'
    coffee:
      src:
        expand: true
        cwd: 'src'
        src: ['**/*.coffee']
        dest: 'app'
        ext: '.js'
      test:
        expand: true
        cwd: 'test/coffee'
        src: ['**/*.coffee']
        dest: 'test/js'
        ext: '.js'
    handlebars:
      templates:
        options:
          commonjs: true
          namespace: 'Templates'
          #processPartialName: (filePath) -> # input:  templates/_header.hbs
            #pieces = filePath.split "/"
            #lastPiece = pieces[pieces.length - 1] # output: _header.hbs
            #lastPiece
        files:
          'app/lib/templates.js': ['src/templates/**/*.html']
    watch:
      srcCoffee:
        files: 'src/**/*.coffee'
        tasks: ['coffee:src']
      testCoffee:
        files: 'test/coffee/**/*.coffee'
        tasks: ['coffee:test']
      templates:
        files: 'src/templates/**/*.html'
        tasks: ['handlebars:templates']

  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-handlebars'

  # Default task(s).
  grunt.registerTask 'default', [
    'handlebars'
    'coffee'
    'watch'
  ]