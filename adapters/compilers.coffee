Adapter = require './adapter'

module.exports = new Adapter

    coffee: (file, cb) ->
        coffee = require 'coffee-script'

        options = {
            bare: @bare ? false
            filename: file.path
            header: @header ? false
        }

        file.read (code) ->
            cb coffee.compile code, options

    less: (file, cb) ->
        less = require 'less'

        options = {
            compress: @compress ? (not @yuicompress)
            yuicompress: @yuicompress ? false
        }

        parser = new less.Parser { paths: [file.dir].concat(@paths ? []) }

        file.read (code) ->
            parser.parse code, (err, tree) ->
                throw err if err
                cb tree.toCSS options

    styl: (file, cb) ->
        stylus = require 'stylus'
        try nib = require 'nib'

        options = {
            filename: file.name
            paths: [file.dir]
            compress: @compress ? true
        }

        file.read (code) ->

            renderer = stylus code, options
            renderer.use nib() if nib?

            renderer.render (err, css) ->
                throw err if err
                cb css

    hbs: (file, cb) ->
        handlebars = require 'handlebars'

        options = {
            context: @context ? 'templates'
        }

        file.read (code) ->
            compiled = handlebars.precompile code
            compiled = "#{options.context}['#{@base}'] = Handlebars.template(#{compiled});\n"
            cb compiled
