module.exports = (grunt) ->
  require('load-grunt-tasks')(grunt)
  grunt.initConfig
    pkg: grunt.file.readJSON 'package.json'
    <% if(tasks['ember']){%>
    emberTemplates:
      compile:
        files:
          'dist/client/templates.js': 'src/client/**/*.hbs'
        options:
          templateName: (sourceFile) ->
            sourceFile.replace /src\/client\/templates\//, ''
    <%}%>

    <% if(framework == 'angular'){%>
    watch:
      clientScripts:
        files: ['src/client/**/*.coffee']
        tasks: ['compileModules', 'uglify']
        options:
          atBegin: true
          livereload: true
      clientTemplates:
        files: ['src/client/**/templates/**/*.html']
        tasks: ['compileTemplates', 'uglify']
        options:
          atBegin: true
          livereload: true
      copyViews:
        files: [<%if (useExpress){%>'src/server/views/**/*.jade'<%} else { %>'src/client/index/html'<%}%>]
        tasks: ['copy:views']
        options:
          atBegin: true
      copyServer:
        files: ['src/server/**/*.coffee']
        tasks: ['coffee:server']
        options:
          atBegin: true
      styles:
        files: ['src/client/styles/**/*.styl']
        tasks: ['stylus:compile']
        options:
          atBegin: true

    concurrent:
      dev:
        tasks: [<%if (useExpress){%>'nodemon:dev', <%}%>'watch']
        options:
          logConcurrentOutput: true

    stylus:
      compile:
        files:
          'dist/client/css/application.css': 'src/client/styles/application.styl'

    <%if (useExpress){%>nodemon:
      dev:
        script: 'dist/server/app.js'
        options:
          env:
            PORT: 8888
          watch: ['dist/server']

    <%}%>coffee:
      server:
        files: [
          cwd: 'src/server'
          src: ['**/*.coffee']
          dest: 'dist/server/'
          ext: '.js'
          expand: true
        ]
        options:
          bare: true

    ngtemplates: {}

    uglify:
      options:
        sourceMap: true
      compile:
        files:
          'dist/client/js/app.js': 'dist/client/js/modules/**/*.js'

    copy:
      views:
        files: <%if (useExpress){%>[
          cwd: 'src/server/views'
          src: '**/*.jade'
          dest: 'dist/server/views'
          expand: true
        ]<%} else { %>
          'dist/client/index.html': 'src/client/index.html'
        <%}%>
<%}%>


<%if(framework == 'angular'){%>
  grunt.registerTask 'compileTemplates', 'Compiles the Angular templates into one template file for each module', ->
    grunt.file.expand('./src/client/modules/*').forEach (module) ->
      config = grunt.config.get('ngtemplates') || {}

      moduleName = module.replace './src/client/modules/', ''

      config[module] =
        cwd: 'src/client/modules'
        src: ["#{moduleName}/templates/*.html"]
        dest: "dist/client/js/modules/#{moduleName}.tmpl.js"
        options:
          module: moduleName
          url: (url) ->
            return url.replace 'templates/', ''

      grunt.config.set 'ngtemplates', config

    grunt.task.run 'ngtemplates'

  grunt.registerTask 'compileModules', 'Compiles the Angular modules into separate files', ->
    grunt.file.expand('./src/client/modules/*').forEach (module) ->
      config = grunt.config.get('coffee') || {}

      moduleName = module.replace './src/client/modules/', ''

      config[module] =
        src: ["#{module}/module.coffee", "#{module}/**/*.coffee"]
        dest: "dist/client/js/modules/#{moduleName}.js"
        options:
          join: true

      grunt.config.set 'coffee', config

    grunt.task.run 'coffee'

  grunt.registerTask 'default', ['concurrent:dev']

  grunt.registerTask 'build', [
    'compileModules',
    'compileTemplates',
    'uglify',
    'copy:views',
    'coffee:server',
    'stylus:compile'
  ]
<%}%>