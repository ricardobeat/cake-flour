Adapter = require './adapter'

module.exports = new Adapter

    js: (file, cb) ->
        uglify = require 'uglify-js'
        file.read (code) ->
            if uglify.minify? # uglify > 2.0
                res = uglify.minify(code, { fromString: true }).code
            else # old API
                { parser: jsp, uglify: pro } = uglify
                res = pro.gen_code pro.ast_squeeze pro.ast_mangle jsp.parse code
            cb res

    css: (file, cb) ->
        csso = require 'csso'
        file.read (code) ->
            res = csso.justDoIt code
            cb res