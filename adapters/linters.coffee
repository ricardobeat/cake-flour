Adapter = require './adapter'

module.exports = new Adapter

    js: (file, cb) ->
        options = @options
        globals = @globals
        jshint = (require 'jshint').JSHINT
        file.read (code) ->
            passed = jshint code, options, globals
            cb passed, jshint.errors