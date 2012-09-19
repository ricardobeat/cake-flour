module.exports =

    js: (file, cb) ->
        { parser: jsp, uglify: pro } = require 'uglify-js'
        file.read (code) ->
            cb pro.gen_code pro.ast_squeeze pro.ast_mangle jsp.parse code