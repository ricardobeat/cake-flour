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
            cb? passed, errors, file

    bundle: (files, options, dest, cb) ->

        return flour.getFiles files, (results) ->
            results.filepath = files
            flour.bundleFiles results, options, dest, cb

    bundleFiles: (files, options, dest, cb) ->

        if files.length is 0
            throw ERROR.NO_MATCH files.filepath

        # No options object
        if not dest? or typeof options isnt 'object'
            [options, dest, cb] = [{}, options, dest]

        options.wrap ?= []

        results = []
        counter = 0

        done = ->
            return unless files.length is ++counter
            shim = new File dest
            sep = if shim.ext is 'js' then "\n;" else "\n"
            shim.buffer = [options.before] + results.join(sep) + [options.after]
            shim.minify (output) ->
                success dest, @, output, 'Packaged', cb

        files.forEach (file, i) ->
            file = new File file
            file.compile (output) ->
                results[i] = [options.wrap[0]] + output + [options.wrap[1]]
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

        if Array.isArray filepath
            counter = 0
            results = []
            end = ->
                return unless filepath.length is ++counter
                # Flatten array
                cb results.reduce (files, f, i) ->
                    Array::push.apply files, f
                    return files
                , []
            filepath.forEach (path, i) -> flour.getFiles path, (files) ->
                results[i] = files
                end()
            return

        dir     = path.dirname filepath
        pattern = path.basename filepath

        try stats = fs.statSync filepath

        if stats?.isFile()
            return cb [filepath]

        if stats?.isDirectory()
            dir = filepath
            pattern = '*.*'

        fs.readdir dir, (err, results) ->
            throw ERROR.NOT_FOUND dir unless results
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
                        if --count is 0 then cb results, files

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
        cb   = dest
        dest = undefined

    # Handle special path cases
    dest = do ->
        # Destination is `*` or nil, use file's own path
        # (`compile 'file.js', '*'`)
        return file.target() if dest in ['*', '.', ''] or dest is null

        # Destination is a directory, use path + own file name 
        try stats = fs.statSync dest
        return file.target(dest) if stats && stats.isDirectory()

        basename = path.basename dest
        dirname  = path.dirname dest

        # Destination is a directory, trailing slash
        return file.target(path.join dirname, basename) if basename.slice(-1) is path.sep

        # Destination is a directory followed by '/*'
        return file.target(dirname) if basename is '*'

        return dest

    # mkdir --parents if needed
    dirname = path.dirname dest
    unless fs.existsSync dirname
        parts = dirname.split(path.sep)
        parts.reduce (p, part, i) ->
            p = path.join p, part
            fs.mkdirSync p unless fs.existsSync p
            return p
        , ''

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
            # apply the callback when all files are done.
            callback = rest[rest.length-1]
            if typeof callback is 'function' and method isnt 'watch'
                results = {}
                count = files.length
                proxy_cb = (i) -> (output, file) ->
                    if method is 'lint'
                        [passed, errors, file] = arguments
                        results[file.name] = { passed, errors, file }
                    else
                        results[file.name] = { output, file }
                    if --count is 0 then callback.call this, results

            for file, i in files
                rest[rest.length-1] = proxy_cb i if proxy_cb
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
