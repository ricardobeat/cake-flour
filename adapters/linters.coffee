module.exports =

    js: (file, args, cb) ->
        # accepts options: flour.lint 'file.js', [options], [globals]
        jshint = (require 'jshint').JSHINT
        file.read (code) ->
            passed = jshint.apply jshint, [code].concat(args)
            cb passed, jshint.errors