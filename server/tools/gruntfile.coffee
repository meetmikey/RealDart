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
    handlebars:
      templates:
        options:
          commonjs: true
          namespace: 'Templates'
        files:
          'app/lib/templates.js': ['src/templates/**/*.html']
    watch:
      srcCoffee:
        files: 'src/**/*.coffee'
        tasks: ['coffee:src']
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