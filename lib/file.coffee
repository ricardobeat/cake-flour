fs   = require 'fs'
path = require 'path'

# File abstraction to simplify I/O, with caching.

passthrough = (file, args..., cb) -> file.read cb

minifiers = require '../adapters/minifiers'
compilers = require '../adapters/compilers'
linters   = require '../adapters/linters'

class File

    constructor: (file, @buffer) ->
        return file if file instanceof File
        @path = file
        @ext  = path.extname file.replace /^\./, ''
        @name = path.basename file
        @base = path.basename file, @ext
        @dir  = path.dirname file

        @lastChange = 0

    read: (cb) ->
        return cb @buffer if @buffer?
        fs.readFile @path, (err, data) ->
            throw err if err
            cb @buffer = data.toString()

    compile: (cb) ->
        (compilers[@ext] ? passthrough) @, cb.bind(@)

    minify: (cb) ->
        (minifiers[@ext] ? passthrough) @, cb.bind(@)

    lint: (args, cb) ->
        (linters[@ext] ? passthrough) @, args, cb.bind(@)

    watch: (fn) ->
        try
            fs.watch @path, (event, filename) ->
                return if event isnt 'change'
                # ignore repeated event misfires
                fn.call @, @ if Date.now() - @lastChange > 1000
                @lastChange = Date.now()
            console.log "Watching".green, @path
        catch e
            console.error "Error watching".red, @path, e
        return

    toString: ->
        @path


module.exports = File