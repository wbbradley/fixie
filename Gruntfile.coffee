module.exports = (grunt) ->
  grunt.initConfig

    pkg: grunt.file.readJSON('package.json')

    coffee:
      options:
        sourceMap: true
      compile:
        files: [{
          expand: true
          cwd: 'coffee/'
          src: ['**/*.coffee']
          dest: '../gen/js'
          ext: '.js'
          }]

    handlebars:
      compile:
        files:
          '../gen/js/handlebars-templates.js': [
            'handlebars/**/*.hbs'
          ]
        options:
          namespace: 'App.Handlebars'
          wrapped: true
          processName: (filename) ->
            filename = filename.replace /handlebars\//, ''
            filename.replace /\.hbs$/, ''

    # less:
    #   development:
    #     options:
    #       dumpLineNumbers: true
    #     files:
    #       '../static/gen/css/style.css': 'less/style.less'

    #   production:
    #     options:
    #       yuicompress: true
    #     files:
    #       '../static/gen/css/style.css': 'less/style.less'

    dust:
      defaults:
        files: [{
          expand: true,
          cwd: 'dust/'
          src: ['**/*.dust']
          dest: '../gen/js/templates.js'
          rename: (dest, src) -> dest
          }]
        options:
          relative: true
          runtime: false
          amd: false

    # uglify:
    #   build:
    #     src: '../static/gen/js/*.js'
    #     dest: '../static/gen/js/all.min.js'

    watch:
      options:
        livereload: true

      coffee:
        files: 'coffee/**/*.coffee'
        tasks: ['coffee']

      less:
        files: 'less/**/*.less'
        tasks: ['less']

      dust:
        files: 'dust/**/*.dust'
        tasks: ['dust']

      handlebars:
        files: 'handlebars/**/*.hbs'
        tasks: ['handlebars']

  grunt.loadNpmTasks('grunt-contrib-coffee')
  grunt.loadNpmTasks('grunt-contrib-less')
  grunt.loadNpmTasks('grunt-contrib-uglify')
  grunt.loadNpmTasks('grunt-contrib-watch')
  grunt.loadNpmTasks('grunt-contrib-handlebars')
  grunt.loadNpmTasks('grunt-dust')

  grunt.registerTask('default', ['coffee', 'dust', 'handlebars'])
