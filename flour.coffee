fs     = require 'fs'
path   = require 'path'
util   = require 'util'
domain = require 'domain'
colors = require 'colors'

# File abstraction to avoid repeat I/O
class File
    constructor: (file, @buffer) ->
        return file if file instanceof File
        @path = file
        @ext  = path.extname file
        @name = path.basename file
        @base = path.basename file, @ext
        @dir  = path.dirname file
    read: (cb) ->
        return cb @buffer if @buffer?
        fs.readFile @path, (err, data) ->
            throw err if err
            cb @buffer = data.toString()
    toString: ->
        @path

passthrough = (file, cb) -> file.read cb

minifiers =
    '.coffee': passthrough
    '.less'  : passthrough
    '.html'  : passthrough

    '.js': (file, cb) ->
        { parser: jsp, uglify: pro } = require 'uglify-js'
        file.read (code) ->
            cb pro.gen_code pro.ast_squeeze pro.ast_mangle jsp.parse code

    # TBD, LESS already compresses output
    '.css': passthrough

compilers = 
    '.js'  : passthrough
    '.css' : passthrough
    '.html': passthrough

    '.coffee': (file, cb) ->
        coffee = require 'coffee-script'
        file.read (code) ->
            cb coffee.compile code

    '.less': (file, cb) ->
        less = require 'less'
        parser = new less.Parser { paths: [file.dir] }
        file.read (code) ->
            parser.parse code, (err, tree) ->
                throw err if err
                cb tree.toCSS(compress: true)

linters =

    '.js': (file, args, cb) ->
        # accepts options: flour.lint 'file.js', [options], [globals]
        jshint = (require 'jshint').JSHINT
        file.read (code) ->
            passed = jshint.apply jshint, [code].concat(args)
            cb passed, jshint.errors

# Success handler. Writes to file if an output path was
# provided, otherwise it just returns the result
finishAction = (action, file, output, dest, cb) ->
    console.log action.magenta, file.toString(), '@', new Date().toLocaleTimeString()
    if not dest? then return cb output
    fs.writeFile dest, output, (err) -> cb? output

# Main object
flour =

    lint: (file, args...) ->
        linters[file.ext] file, args, (passed, errors) ->
            if passed
                console.log "OK".green.inverse, file.path
                return
        
            for e in errors
                pos = "[L#{e.line}:C#{e.character}]"
                console.log pos.red, e.reason.grey
                console.log "NOT OK".magenta.inverse, file.path.bold

    compile: (file, dest, cb) ->
        compilers[file.ext] file, (output) ->
            finishAction 'Compiled', file, output, dest, cb

    minify: (file, dest, cb) ->
        minifiers[file.ext] file, (output) ->
            finishAction 'Minified', file, output, dest, cb

    watch: (file, fn) ->
        lastChange = 0
        try
            fs.watch file.path, (event, filename) ->
                return if event isnt 'change'
                # ignore repeated event misfires
                fn file if Date.now() - lastChange > 1000
                lastChange = Date.now()
            console.log "Watching".green, file.path
        catch e
            console.error "Error watching".red, file.path
        return

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
            minifiers[shim.ext] shim, (output) ->
                finishAction 'Packaged', shim, output, dest, cb

        files.forEach (file, i) ->
            file = new File file
            compilers[file.ext] file, (code) ->
                results[i] = code
                done()

        return

    noConflict: ->
        for m in globals
            delete global[m]
            if global['_'+m]? then global[m] = global['_'+m]
        return

    minifiers: minifiers
    compilers: compilers


    # Get a list of files that match an extension
    getFiles: (file, cb) ->
        file = new File file
        fs.readdir file.dir, (err, results) ->
            results = results.filter (f) -> path.extname(f) is file.ext
            results = results.map (f) -> path.join file.dir, f
            cb results

# Error handler
failed = (what, file, e) ->
    console.error "Error #{what}".red.inverse, file.toString()
    if e.type and e.filename
        console.error "[L#{e.line}:C#{e.column}]".yellow,
            "#{e.type} error".yellow
            "in #{e.filename}:".grey
            e.message
    else
        console.error e.type?.yellow, e.message?.grey

# Extend all functions that accept a file parameter to:
#   - accept both arrays and *.xxx paths
#   - capture errors using domains
#   - feed the original method a File instance
['lint', 'compile', 'minify', 'watch'].forEach (method) ->

    # create domain and attach to method
    dm = domain.create()

    # save original and overwrite method
    original = flour[method]
    flour[method] = dm.bind (file, rest...) ->

        dm.on 'error', (err) -> failed "#{method.replace(/e$/,'')}ing", file, err

        if util.isArray file
            original.apply flour, [new File f].concat(rest) for f in file
            return

        file = new File file

        if file.base is '*'
            flour.getFiles file, (files) ->
                flour[method].apply flour, [files].concat(rest)
            return
        
        original.apply flour, [file].concat(rest)

# export globals
for m in ['lint', 'compile', 'bundle', 'minify', 'watch', 'getFiles']
    if global[m]? then global['_'+m] = global[m]
    global[m] = flour[m]

module.exports = flour
