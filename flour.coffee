fs     = require 'fs'
path   = require 'path'
util   = require 'util'
domain = require 'domain'
colors = require 'colors'
mm     = require 'minimatch'

File   = require './lib/file'
logger = require './lib/logger'

# Main object / API

flour =

    silent: (state = true) ->
        logger.silent = state

    compile: (file, dest, cb) ->
        file.compile (output) ->
            success dest, @, output, 'Compiled', cb

    minify: (file, dest, cb) ->
        file.minify (output) ->
            success dest, @, output, 'Minified', cb

    lint: (file, cb) ->
        file.lint (passed, errors) ->
            if passed
                logger.log " OK ".green.inverse, file.path
            else
                logger.log " NOT OK ".magenta.inverse, file.path.bold
                for e in errors when e?
                    pos = "[L#{e.line}:#{e.character}]"
                    logger.log pos.red, e.reason.grey
            cb? passed, errors

    bundle: (files, dest, cb) ->

        unless util.isArray files
            return flour.getFiles files, (results) ->
                flour.bundle results, dest, cb

        if files.length is 0
            throw new Error 'No files match'

        results = []
        counter = 0

        done = ->
            return unless files.length is ++counter
            shim = new File dest, results.join("\n")
            shim.minify (output) ->
                success dest, @, output, 'Packaged', cb

        files.forEach (file, i) ->
            file = new File file
            file.compile (output) ->
                results[i] = output
                done()

        return

    watch: (file, fn) ->
        file.watch fn

    noConflict: ->
        for m in globals
            delete global[m]
            if global['_'+m]? then global[m] = global['_'+m]
        return

    # Get a list of files from a wildcard path (*.ext)
    getFiles: (filepath, cb) ->
        dir     = path.dirname filepath
        pattern = path.basename filepath

        try stats = fs.statSync filepath

        if stats?.isFile()
            return cb [filepath]

        if stats?.isDirectory()
            dir = filepath
            pattern = '*.*'

        fs.readdir dir, (err, results) ->
            results = results.filter mm.filter pattern
            results = results.map (f) -> path.join dir, f
            cb results

    # Get file(s)' contents
    get: (filepath, cb) ->
        file = new File filepath

        if file.base is '*'
            flour.getFiles filepath, (files) ->
                results = []
                count = files.length
                files.forEach (f, i) ->
                    new File(f).read (output) ->
                        results[i] = output
                        if --count is 0 then cb results
        else
            file.read cb

    # Load adapters
    minifiers : require './adapters/minifiers'
    compilers : require './adapters/compilers'
    linters   : require './adapters/linters'

# Success handler. Writes to file if an output path was
# provided, otherwise it just returns the result
success = (dest, file, output, action, cb) ->
    # Handle callback-only calls
    #     flour.compile 'file', (output) ->
    if typeof dest is 'function'
        [cb, dest] = [dest, null]

    if dest?
        fs.writeFile dest, output, (err) -> cb? output
    else
        cb output

    logger.log "#{action.magenta} #{file} @ #{new Date().toLocaleTimeString()}"

# Error handler
failed = (what, file, e) ->
    logger.error "Error #{what}".red.inverse, file?.toString()
    if e.type and e.filename
        logger.error "[L#{e.line}:C#{e.column}]".yellow,
            "#{e.type} error".yellow
            "in #{e.filename}:".grey
            e.message
    else
        logger.error e.type?.yellow, e.message?.grey

# Overwrite all methods that accept a file parameter to:
#   - accept both arrays and *.xxx paths
#   - capture errors using domains
#   - feed the original method a File instance
['lint', 'compile', 'minify', 'watch'].forEach (method) ->

    original = flour[method]

    flour[method] = (file, rest...) ->

        dm = domain.create()
        dm.on 'error', (err) ->
            failed "#{method.replace(/e$/,'')}ing", file, err

        if util.isArray file
            dm.bind(original).apply flour, [new File f].concat(rest) for f in file
            return

        # Create a File object with the given path. If it turns out
        # to be a wildcard path, we just discard it.
        file = new File file

        # Handle wildcard paths.
        if file.base is '*'
            flour.getFiles file.path, (files) ->
                flour[method].apply flour, [files].concat(rest)
            return

        # Or call original method if it's a single file.
        dm.bind(original).apply flour, [file].concat(rest)

# Global methods

globals = ['lint', 'compile', 'bundle', 'minify', 'watch', 'get']

for m in globals
    if global[m]? then global['_'+m] = global[m]
    global[m] = flour[m]

module.exports = flour
