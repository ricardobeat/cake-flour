flour  = require 'flour'
fs     = require 'fs'

task 'build:styles', ->
    bundle [
        'stylesheets/skeleton.css'
        'stylesheets/base.css'
        'stylesheets/layout.less'
        'vendor/rainbow/themes/github.css'
    ], 'resources/styles.css'

task 'render', ->
    fs.readFile 'layout.html', (err, file) ->
        fs.writeFileSync 'index.html', file.toString().replace /\{\{(\w+\.\w+)\}\}/g, (m, file) ->
            return try fs.readFileSync("samples/#{file}").toString()

task 'watch', ->
    invoke 'build:styles'
    watch 'stylesheets/*', -> invoke 'build:styles'

    invoke 'render'
    watch [
        'layout.html'
        'samples/'
    ], -> invoke 'render'

task 'self', ->
    child = null
    start = ->
        console.log "Restarting..."
        child = require('child_process').spawn('cake', ['watch'], { stdio: 'inherit', stdout: 'inherit', stderr: 'inherit' })

    watch './Cakefile', ->
        child.kill()
        start()

    start()
