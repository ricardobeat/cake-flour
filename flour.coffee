fs     = require 'fs'
path   = require 'path'
less   = require 'less'
coffee = require 'coffee-script'
colors = require 'colors'
uglify = require 'uglify-js'
jshint = (require 'jshint').JSHINT

# generic error handler
failed = (file, err) ->
    console.error "Error compiling".red, file
    console.error err
    process.exit 1

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

    # compile LESS/CoffeeScript
    compile: (file, dest, cb) ->
        if typeof dest is 'function' then cb = dest
        ext = path.extname file
        source = null

        success = (output) ->
            console.log "Compiled".magenta, file, '@', new Date().toLocaleTimeString()
            if dest?
                return fs.writeFile dest, output, (err) ->
                    cb? output
            cb output

        fs.readFile file, 'utf8', (err, code) ->
            failed(file, err) if err
            source = code
            switch ext
                when '.js'
                    cb ';' + code
                when '.coffee'
                    flour.compileCoffee code, success
                when '.less'
                    flour.compileLess code, [path.dirname file], success
        return

    minifyJS: (code, cb) ->
        { parser: jsp, uglify: pro } = uglify
        output = pro.gen_code pro.ast_squeeze pro.ast_mangle jsp.parse code
        cb output

    minify: (file, cb) ->
        fs.readFile file, 'utf8', (err, data) ->
            failed(source, err) if err
            if /js|coffee/.test path.extname file
                flour.minifyJS data, cb
            else
                cb data

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
        lastChange = 0
        try
            fs.watch file, (event, filename) ->
                return if event isnt 'change'
                # ignore repeated event misfires
                fn file if Date.now() - lastChange > 1000
                lastChange = Date.now()
            console.log "Watching".green, file
        catch e
            console.error "Error watching".red, file
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