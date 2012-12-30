fs     = require 'fs'
path   = require 'path'
util   = require 'util'
domain = require 'domain'
colors = require 'colors'
mm     = require 'minimatch'

File   = require './lib/file'
logger = require './lib/logger'
ERROR  = require './lib/errors'

isWild = (str) -> /[*!{}|}]/.test str

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
                results.filepath = files
                flour.bundle results, dest, cb

        if files.length is 0
            throw ERROR.NO_MATCH files.filepath

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
        if isWild filepath
            return flour.getFiles filepath, (files) ->
                results = []
                count = files.length
                files.forEach (f, i) ->
                    new File(f).read (output) ->
                        results[i] = output
                        if --count is 0 then cb results

        new File(filepath).read cb

    # Load adapters
    minifiers : require './adapters/minifiers'
    compilers : require './adapters/compilers'
    linters   : require './adapters/linters'

# Success handler. Writes to file if an output path was
# provided, otherwise it just returns the result
success = (dest, file, output, action, cb) ->

    # flour.compile 'file.js', (output) ->
    if typeof dest is 'function'
        [cb, dest] = [dest, null]

    # flour.compile 'src/*.coffee', '*'
    else if dest is '*' or dest is '.' or dest is null or dest is ''
        dest = file.target()

    # flour.compile 'src/*.coffee', 'js/'
    else
        dir_dest = dest
        unless dir_dest[-1..] is '/'
            dir_dest = path.dirname dest
            basename = path.basename dest

        try stats = fs.statSync dir_dest
        if (!basename or basename is '*') and stats?.isDirectory()
            dest = file.target dir_dest

    if dest?
        dest = path.join process.cwd(), dest
        fs.writeFile dest, output, (err) -> cb? output, file
    else
        cb? output, file

    logger.log "#{action.magenta} #{file} @ #{new Date().toLocaleTimeString()}"

# Overwrite all methods that accept a file parameter to:
#   - accept both arrays and *.xxx paths
#   - capture errors using domains
#   - feed the original method a File instance
['lint', 'compile', 'minify', 'watch'].forEach (method) ->

    original = flour[method]

    flour[method] = (files, rest...) ->

        dm = domain.create()
        dm.on 'error', (err) ->
            logger.fail "#{method.replace(/e$/,'')}ing", files.filepath or files, err

        if util.isArray files
            throw ERROR.NO_MATCH files.filepath if files.length < 1

            # Handle multiple file outputs. Buffer results and
            # call the callback function a single time.
            callback = rest[rest.length-1]
            if typeof callback is 'function'
                results = []
                count = files.length
                proxy_cb = (i) -> (output, file) ->
                    results[i*2] = output
                    results[i*2+1] = file
                    if --count is 0 then callback.apply this, results
                rest[rest.length-1] = proxy_cb

            for file, i in files
                rest[rest.length-1] = proxy_cb i
                dm.bind(original).apply flour, [new File file].concat(rest)

            return

        # Create a File object with the given path. If it turns out
        # to be a wildcard path, we just discard it.
        file = new File files

        # Handle wildcard paths.
        if isWild file.base
            flour.getFiles file.path, (files) ->
                # Make the file name available to the proxied function
                # (there is probably a better way)
                files.filepath = file.path
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
