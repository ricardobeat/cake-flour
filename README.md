Flour
==========

**Flour** is a set of simple build tools for your Cakefiles.

![image](http://i.imgur.com/yIxF9.jpg)

## Usage

`npm install flour`, don't forget to add it to your `package.json`. Do `require 'flour'` at the top of your Cakefile, the tools are added to global scope.

This is what a typical Cakefile could look like:

    require 'flour'

    task 'lint', 'Check javascript syntax', ->
        lint 'js/feature.js'

    task 'build:plugins', ->
        bundle [
            'vendor/underscore.js'
            'vendor/hogan.js'
            'vendor/backbone.js'
        ], 'js/plugins.js'

    task 'build:coffee', ->
        compile 'coffee/app.coffee', 'js/app.js'

    task 'build:less', ->
        compile 'less/main.less', 'css/main.css'

    task 'build', ->
        invoke 'build:plugins'
        invoke 'build:coffee'
        invoke 'build:less

    task 'watch', ->
        invoke 'build:less'
        invoke 'build:coffee'

        watch 'less/*.less', -> invoke 'build:less'
        watch 'coffee/app.coffee', -> invoke 'build:coffee'

(if the global pollution hurts your feelings you can remove them with `flour.noConflict()`. That will bring the global object back to it's previous state)

Each of these functions can accept either a single file path or an array of files. Simple wildcard paths like `*.xxx` are also accepted. Example using `watch` with a list of files:

    watch [
        'less/main.less'
        'less/reset.less'
        'less/print.less'
    ], -> invoke 'build:less'

You can also access the resulting output by passing a callback:

    compile 'coffee/app.coffee', (output) ->
        # do something with the compiled output
        mail.send subject: 'Project file', to: 'grandma@hotmail.com', body: output

    # if you don't trust the CS compiler
    compile 'coffee/app.coffee', 'js/app.js', -> lint 'js/app.js'

## Reference

### Compile

Compiles LESS and CoffeeScript files:

    compile(file, [destination], [callback])

##### Usage

    compile 'app.coffee', 'app.js'

    compile 'cold.coffee', 'app.js', (output) ->
        console.log 'Done!'

    compile 'cold.coffee', (output) ->
        console.log output.transform()

### Bundle

Compile, minify and join a set of files (preserving order):

    bundle(files, destination)

##### Usage

    bundle [
        'lib/jquery.js'
        'lib/underscore.js'
        'lib/backbone.js'
    ], 'js/bundle.js'

    bundle 'js/*.js', 'js/all.js'

### Watch

Watch files for changes:

    watch(files, action)

##### Usage

    watch 'src/app.coffee', ->
        compile 'lib/app.js'

    # best used with predefined tasks:

    task 'build', ->
        bundle '*.coffee', 'app.js'

    task 'watch', ->
        watch [
            'modules.coffee'
            'user.coffee'
            'main.coffee'
        ], ->
            invoke 'build'

    # or
    watch '*.coffee', -> invoke 'build'

### Lint

Check file syntax (uses [JSHint](http://jshint.com)):

    lint(file, [options], [globals]) # see http://www.jshint.com/options/

#### Usage

    task 'lint', ->

        lint 'scripts/*.js'

### Minify

Minify files (currently only Javascript using [UglifyJS](https://github.com/mishoo/UglifyJS)):

    minify(file, [destination], [callback])

## Extensibility

You can add new minifiers and compilers to `flour`:

    flour.minifiers['.stupid'] = (file, cb) ->
        file.read (code) ->
            cb code.replace(/\s*/, '')

    flour.compilers['.odd'] = (file, cb) ->
        odd = require 'odd-lib'
        file.read (code) ->
            cb odd.compile code

## Tricks

#### Disable the JS minifier for development

    task 'watch', ->
        # pass code through unchanged
        flour.minifiers['.js'] = (file, cb) -> cb file.buffer

        # see useful line numbers when debugging!
        watch 'scripts/*.coffee', -> invoke 'build'

#### Pre-compile Hogan templates

    flour.compilers['.mustache'] = (file, cb) ->
        hogan = require 'hogan.js'
        file.read (code) ->
            cb "App.templates['#{file.base}']=${hogan.compile code, asString: true};"

    task 'build:templates', ->
        bundle 'views/*.mustache', 'resources/views.js'

## Why?

While Grunt, brewerjs, H5BP-build-script and other similar projects have the same (and some more advanced) capabilities, they are increasingly complex. The goal of Flour is to provide a small, short and sane API for the most common build tasks without requiring you to adjust your project structure, install extra tools or create long configuration files. Cake is all you need!

#### TODO:
- tests
- figure out how to magically bundle hogan templates
