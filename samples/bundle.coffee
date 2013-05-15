task 'build:vendor', ->
    bundle [
        'vendor/underscore.js'
        'vendor/zepto.js'
        'vendor/backbone.js'
    ], 'build/vendor.js'

task 'build:source', ->
    bundle [
        'sources/bootstrap.coffee'
        'sources/app.coffee'
        'sources/views/*.coffee'
    ], 'build/app.js'