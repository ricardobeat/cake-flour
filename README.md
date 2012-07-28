Flour
==========

**Flour** is a set of easy-to-use helper methods for your Cakefiles. It is also the base ingredient for lots of delicious things.

![image](http://i.imgur.com/yIxF9.jpg)

It adds a bunch of functions to global scope:

- `lint(file, [options], [globals])`: check javascript syntax using JSHint 
- `compile(file, [dest], [cb])`: compile LESS or CoffeeScript files (automatic)
- `bundle(output, filesArray)`: compile, minify and concat a group of files
- `minify(file, [dest], [cb])`: minify files using uglify-js
- `watch(file, fn)`: do something when file changes. Accepts an array of filenames

(If that hurts your feelings you can remove them with `flour.noConflict()`. That will bring the global object to it's previous state)

## Usage

Just `npm install flour`.

This is what a typical Cakefile could look like:

    require 'flour'

    task 'lint', 'Check javascript syntax', ->
        lint 'js/feature.js'

    task 'build:plugins', 'Bundle javascript plugins', ->
        bundle 'js/plugins.js', [
            'vendor/underscore.js'
            'vendor/hogan.js'
            'vendor/backbone.js'
        ]

    task 'build:coffee', 'Compile CoffeeScript', ->
        compile 'coffee/app.coffee', 'js/app.js'

    task 'build:less', 'Compile LESS', ->
        compile 'less/main.less', 'css/main.css'

    task 'build', ->
        invoke 'build:plugins'
        invoke 'build:coffee'
        invoke 'build:less

    task 'watch', ->
        invoke 'build:less'
        invoke 'build:coffee'

        watch [
            'less/main.less'
            'less/reset.less'
            'less/print.less'
        ], -> invoke 'build:less'

        watch 'coffee/app.coffee', -> invoke 'build:coffee'

## Why?

Grunt, brewerjs, H5BP-build-script and other similar projects are just *too complex*. A simple Cakefile should be enough to make you happy.

#### TODO:
- tests
- abstract file I/O
- error handling is crap
- modularize transform functions to allow other languages/compilers
