fs     = require 'fs'
path   = require 'path'
domain = require 'domain'
gaze   = require 'gaze'

logger = require './logger'

# File abstraction to simplify I/O, with caching.

passthrough = (file, args..., cb) -> file.read cb

class File

    constructor: (file, @context, @buffer) ->
        @path = file
        @ext  = path.extname(file).replace /^\./, ''
        @name = path.basename file
        @base = path.basename file, '.'+@ext
        @dir  = path.dirname file

        @lastChange = 0

        @domain = domain.create()
        @domain.on 'error', (err) =>
            logger.fail @action, @path, err

    read: (cb) ->
        return cb @buffer if @buffer?
        fs.readFile @path, (err, data) =>
            throw err if err
            cb.call @, @buffer = data.toString()

    compile: (cb) ->
        @action = 'compiling'
        compiler = @context.compilers[@ext] or passthrough
        @domain.run =>
            compiler.call compiler, @, cb.bind(@)

    minify: (cb) ->
        @action = 'minifying'
        minifier = @context.minifiers[@ext] or passthrough
        @domain.run =>
            minifier.call minifier, @, cb.bind(@)

    lint: (cb) ->
        @action = 'linting'
        linter = @context.linters[@ext] or passthrough
        @domain.run =>
            linter.call linter, @, cb.bind(@)

    watch: (fn) ->
        fn = fn.bind @
        try
            gaze(@path).on('all', fn)
            logger.log "Watching".green, @path
        catch e
            logger.fail 'watching', @path, e
        return @watcher

    targetExtension: ->
        switch @ext
            when 'less', 'styl' then 'css'
            when 'coffee'       then 'js'
            when 'hbs'          then 'js'
            when 'md'           then 'html'
            else @ext

    target: (dir) ->
        path.join dir or @dir, "#{@base}.#{@targetExtension()}"

    toString: ->
        @path


module.exports = File
