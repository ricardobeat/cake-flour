module.exports =

    js: (file, cb) ->
        uglify = require 'uglify-js'
        file.read (code) ->
            res = uglify.minify code, { fromString: true }
            cb res.code