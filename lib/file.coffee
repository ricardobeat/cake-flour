fs    = require 'fs'
path  = require 'path'
hound = require 'hound'

logger = require './logger'

# File abstraction to simplify I/O, with caching.

passthrough = (file, args..., cb) -> file.read cb

minifiers = require '../adapters/minifiers'
compilers = require '../adapters/compilers'
linters   = require '../adapters/linters'

class File

    constructor: (file, @buffer) ->
        return file if file instanceof File
        @path = file
        @ext  = path.extname(file).replace /^\./, ''
        @name = path.basename file
        @base = path.basename file, '.'+@ext
        @dir  = path.dirname file

        @lastChange = 0

    read: (cb) ->
        return cb @buffer if @buffer?
        fs.readFile @path, (err, data) =>
            throw err if err
            cb @buffer = data.toString()

    compile: (cb) ->
        compiler = compilers[@ext] or passthrough
        compiler.call compiler, @, cb.bind(@)

    minify: (cb) ->
        minifier = minifiers[@ext] or passthrough
        minifier.call minifier, @, cb.bind(@)

    lint: (cb) ->
        linter = linters[@ext] or passthrough
        linter.call linter, @, cb.bind(@)

    watch: (fn) ->
        fn = fn.bind @
        try
            @watcher = hound.watch @path
            for evt in ['create', 'change', 'delete']
                @watcher.on evt, fn
            logger.log "Watching".green, @path
        catch e
            logger.error "Error watching".red, @path, e
        return @watcher

    toString: ->
        @path


module.exports = File