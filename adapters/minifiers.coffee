Adapter = require './adapter'

module.exports = new Adapter

    js: (file, cb) ->
        uglify = require 'uglify-js'

        options = Adapter.getOptions this
        options.fromString = true

        file.read (code) ->
            if uglify.minify? # uglify > 2.0
                res = uglify.minify(code, options).code
            else # old API
                { parser: jsp, uglify: pro } = uglify
                res = pro.gen_code pro.ast_squeeze pro.ast_mangle jsp.parse code
            cb res

    css: (file, cb) ->
        csso = require 'csso'

        options = Adapter.getOptions this, {
            restructure: false
        }

        file.read (code) ->
            res = csso.justDoIt code, options.restructure
            cb res