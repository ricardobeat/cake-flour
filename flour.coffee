fs     = require 'fs'
path   = require 'path'
util   = require 'util'
domain = require 'domain'
colors = require 'colors'

File = require './lib/file'

#### Flour object

flour =

    compile: (file, dest, cb) ->
        file.compile (output) ->
            success dest, @, output, 'Compiled', cb

    minify: (file, dest, cb) ->
        file.minify (output) ->
            success dest, @, output, 'Minified', cb

    lint: (file, args...) ->
        file.lint args, (passed, errors) ->
            if passed
                console.log "OK".green.inverse, file.path
                return
            for e in errors
                pos = "[L#{e.line}:C#{e.character}]"
                console.log pos.red, e.reason.grey
                console.log "NOT OK".magenta.inverse, file.path.bold

    bundle: (files, dest, cb) ->

        if not util.isArray files
            flour.getFiles files, (results) ->
                flour.bundle results, dest, cb
            return

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
        ext = path.extname filepath
        dir = path.dirname filepath

        fs.readdir dir, (err, results) ->
            results = results.filter (f) -> path.extname(f) is ext
            results = results.map (f) -> path.join dir, f
            cb results

    # Get file(s)' contents
    get: (filepath, cb) ->
        file = new File filepath

        if file.base is '*'
            getFiles filepath, (files) ->
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
    if dest?
        fs.writeFile dest, output, (err) -> cb? output
    else
        cb output

    console.log "#{action.magenta} #{file} @ #{new Date().toLocaleTimeString()}"

# Error handler
failed = (what, file, e) ->
    console.error "Error #{what}".red.inverse, file?.toString()
    if e.type and e.filename
        console.error "[L#{e.line}:C#{e.column}]".yellow,
            "#{e.type} error".yellow
            "in #{e.filename}:".grey
            e.message
    else
        console.error e.type?.yellow, e.message?.grey

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

#### Globals

globals = ['lint', 'compile', 'bundle', 'minify', 'watch', 'get']

for m in globals
    if global[m]? then global['_'+m] = global[m]
    global[m] = flour[m]

module.exports = flour
