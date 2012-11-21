module.exports =

    js: (file, cb) ->
        options = @options
        globals = @globals
        jshint = (require 'jshint').JSHINT
        file.read (code) ->
            passed = jshint code, options, globals
            cb passed, jshint.errors