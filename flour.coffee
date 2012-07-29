fs     = require 'fs'
path   = require 'path'
domain = require 'domain'
less   = require 'less'
coffee = require 'coffee-script'
colors = require 'colors'
uglify = require 'uglify-js'
jshint = (require 'jshint').JSHINT

# generic error handler
failed = (file, e) ->
    console.error "Error compiling".red.inverse, file.toString()
    if e.type and e.filename
        console.error "[L#{e.line}:C#{e.column}]".yellow,
            "#{e.type} error".yellow
            "in #{e.filename}:".grey
            e.message
    else
        console.error e.type.yellow, e.message.grey

# write to file if an output path was provided
# otherwise just return the result to the callback
finishAction = (action, file, output, dest, cb) ->
    console.log action.magenta, file.toString(), '@', new Date().toLocaleTimeString()
    if not dest? then return cb output
    fs.writeFile dest, output, (err) -> cb? output

class File
    constructor: (file) ->
        return file if file instanceof File
        @path = file
        @ext  = path.extname(file)[1..]
        @name = path.basename file
        @base = path.basename file, @ext
        @dir  = path.dirname file
    read: (cb) ->
        fs.readFile @path, (err, data) ->
            cb err, data?.toString()
    toString: ->
        @path

# main object
flour =
    lint: (files, options = {}, globals = {}) ->
        if not (files instanceof Array)
            files = [files]
        for file in files
            result = jshint fs.readFileSync(file).toString(), options, globals
            if result
                console.log "OK".green.inverse, file
            else
                console.log "NOT OK".magenta.inverse, file.bold
                for e in jshint.errors
                    pos = "[L#{e.line}:C#{e.character}]"
                    console.log pos.red, e.reason.grey
        
    compileCoffee: (code, cb) ->
        cb ';' + coffee.compile code

    compileLess: (code, paths = [], cb) ->
        parser = new less.Parser { paths }
        parser.parse code, (err, tree) ->
            throw err if err
            cb tree.toCSS(compress: true)

    compile: (file, dest, cb) ->
        compileDomain = domain.create()
        compileDomain.on 'error', (err) -> failed file, err
    
        if typeof dest is 'function' then [cb, dest] = [dest, null]
        file = new File file

        success = (output) ->
            finishAction 'Compiled', file, output, dest, cb

        file.read compileDomain.bind (err, code) ->
            switch file.ext
                when 'js'
                    cb ';' + code
                when 'coffee'
                    flour.compileCoffee code, success
                when 'less'
                    flour.compileLess code, [file.dir], success
        return

    minifyJS: (code, cb) ->
        { parser: jsp, uglify: pro } = uglify
        output = pro.gen_code pro.ast_squeeze pro.ast_mangle jsp.parse code
        cb output

    minify: (file, dest, cb) ->
        if typeof dest is 'function' then [cb, dest] = [dest, null]
        file = new File file

        success = (output) ->
            finishAction 'Minified', file, output, dest, cb

        file.read (err, data) ->
            failed(file, err) if err
            switch ext
                when 'js', 'coffee'
                    flour.minifyJS data, success
                else
                    success data

    # concatenate and minify files -> dest
    # optional callback
    bundle: (dest, files, cb) ->

        ext = path.extname files[0]
        passthrough = (c, cb) -> cb c
        min = if /js|coffee/.test(ext) then flour.minifyJS else passthrough

        results = []
        done = 0

        writeBundle = (results) ->
            fs.writeFile dest, results, 'utf8', ->
                console.log "Packaged".magenta, dest

        files.forEach (file, i) ->
            flour.compile file, (code) ->
                results[i] = code
                if files.length is ++done
                    results = results.join "\n"
                    min results, writeBundle

    watchFile: (file, fn) ->
        file = new File file

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

    watch: (files, fn) ->
        if not (files instanceof Array)
            flour.watchFile files, fn
        else
            flour.watchFile file, fn for file in files

    noConflict: ->
        for m in globals
            delete global[m]
            if global['_'+m]? then global[m] = global['_'+m]

globals = ['lint', 'compile', 'bundle', 'minify', 'watch']

for m in globals
    if global[m]? then global['_'+m] = global[m]
    global[m] = flour[m]

module.exports = flour
