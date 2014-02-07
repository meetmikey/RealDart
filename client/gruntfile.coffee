module.exports = (grunt) ->

  # Project configuration.
  grunt.initConfig
    pkg: grunt.file.readJSON 'package.json'
    coffee:
      bb:
        src: [
          'bb/namespace.coffee'
          'bb/constant.coffee'
          'bb/config.coffee'
          'bb/router.coffee'
          'bb/app.coffee'
          'bb/helper/**/*.coffee'
          'bb/view/base.coffee'
          'bb/view/**/!(base).coffee'
          'bb/model/base.coffee'
          'bb/model/**/!(base).coffee'
          'bb/decorator/**/*.coffee'
          'bb/collection/base.coffee'
          'bb/collection/**/!(base).coffee'
        ]
        dest: '../public/js/app.js'
    concat:
      vendorJS:
        src: [
          'vendor/js/jquery-1.11.0.min.js'
          'vendor/js/jquery-validate-1.11.1.min.js'
          'vendor/js/underscore-1.5.2.min.js'
          'vendor/js/backbone-1.1.0.min.js'
          'vendor/js/handlebars-1.3.0-runtime.js' #runtime requires that the templates have been precompiled
          'vendor/js/bootstrap-3.1.0.min.js'
        ]
        dest: '../public/js/vendor.js'
      vendorCSS:
        src: ['vendor/css/**/*.css']
        dest: '../public/css/vendor.css'
    uglify:
      app:
        options:
          sourceMap: true
        files:
          '../public/js/app.min.js': '../public/js/app.js'
      template:
        options:
          sourceMap: true
        files:
          '../public/js/template.min.js': '../public/js/template.js'
      vendor:
        files:
          '../public/js/vendor.min.js': '../public/js/vendor.js'
    less:
      app:
        files:
          '../public/css/app.css': 'less/**/*.less'
    handlebars:
      template:
        options:
          namespace: 'RDTemplates'
        files:
          '../public/js/template.js': ['template/**/*.html']
    watch:
      coffeeBB:
        files: 'bb/**/*.coffee'
        tasks: ['coffee:bb']
      concatVendorJS:
        files: 'vendor/js/**/*.js'
        tasks: ['concat:vendorJS']
      concatVendorCSS:
        files: 'vendor/css/**/*.css'
        tasks: ['concat:vendorCSS']
      uglifyApp:
        files: '../public/js/app.js'
        tasks: ['uglify:app']
      uglifyTemplate:
        files: '../public/js/template.js'
        tasks: ['uglify:template']
      uglifyVendor:
        files: '../public/js/vendor.js'
        tasks: ['uglify:vendor']
      lessApp:
        files: 'less/**/*.less'
        tasks: ['less:app']
      template:
        files: 'template/**/*.html'
        tasks: ['handlebars:template']

  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-concat'
  grunt.loadNpmTasks 'grunt-contrib-uglify'
  grunt.loadNpmTasks 'grunt-contrib-handlebars'
  grunt.loadNpmTasks 'grunt-contrib-less'
  grunt.loadNpmTasks 'grunt-contrib-watch'

  # Default task(s).
  grunt.registerTask 'default', [
    'coffee'
    'concat'
    'uglify'
    'handlebars'
    'less'
    'watch'
  ]