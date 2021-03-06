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
    watch:
      srcCoffee:
        files: 'src/**/*.coffee'
        tasks: ['coffee:src']
      testCoffee:
        files: 'test/coffee/**/*.coffee'
        tasks: ['coffee:test']

  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-contrib-coffee'

  # Default task(s).
  grunt.registerTask 'default', [
    'coffee'
    'watch'
  ]