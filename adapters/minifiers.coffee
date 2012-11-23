module.exports =

    js: (file, cb) ->
        uglify = require 'uglify-js'
        file.read (code) ->
            res = uglify.minify code, { fromString: true }
            cb res.code

    css: (file, cb) ->
        csso = require 'csso'
        file.read (code) ->
            res = csso.justDoIt code
            cb res