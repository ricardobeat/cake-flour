module.exports =

    coffee: (file, cb) ->
        coffee = require 'coffee-script'
        file.read (code) ->
            cb coffee.compile code

    less: (file, cb) ->
        less = require 'less'
        parser = new less.Parser { paths: [file.dir] }
        file.read (code) ->
            parser.parse code, (err, tree) ->
                throw err if err
                cb tree.toCSS { compress: true }

    styl: (file, cb) ->
        stylus = require 'stylus'
        try nib = require 'nib'

        file.read (code) ->
            opts =
                filename: file.name
                paths: [file.dir]
                compress: true

            renderer = stylus code, opts
            renderer.use nib() if nib

            renderer.render (err, css) ->
                throw err if err
                cb css
