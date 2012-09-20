Flour
==========

**Flour** is a set of simple build tools for your Cakefiles.

#### Changelog

##### v0.3.2
- add [node-hound](http://github.com/beefsack/node-hound) as a dependency for file watching
- watch whole directory trees: `watch `src/`, -> invoke 'build' (listens for new files and deletes too)
- fix error handlers leak

##### v0.3.1
- fix extension handling bug
##### v0.3.0
- flour doesn't install it's adapter dependencies anymore, it's up to you to add them to your project's `package.json`

![image](http://i.imgur.com/yIxF9.jpg)

## Usage

Add `flour` and your required pre-processors/compilers to your `package.json`:

    {
      "name": "dancingrobot",
      ...
      "dependencies": {
        "flour": "",
        "uglify-js": "",
        "coffee-script": ""
      },
      ...
    }

Then run `npm install`, and `require 'flour'` at the top of your Cakefile. A few methods are available in the global scope.

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

## Adapters

These are the current adapters and the required modules:

### Compilers

* CoffeeScript: `coffee-script`
* LESS: `less`
* Stylus: `stylus`

### Minifiers

* Javascript: `uglify-js`

### Linters

* Javascript: 'jshint'

Creating new adapters is very easy, take a look at the `adapters/` folder for guidance.

## Reference

### Compile

Compiles CoffeeScript, LESS or Stylus files:

    compile(file, [destination], [callback])

##### Usage

    compile 'app.coffee', 'app.js'

    compile 'cold.coffee', 'app.js', (output) ->
        console.log 'Done!'

    compile 'cold.coffee', (output) ->
        console.log output.transform()

### Bundle

Compile, minify and join a set of files:

    bundle(files, destination)

##### Usage

    // preservers the list order
    bundle [
        'lib/jquery.js'
        'lib/underscore.js'
        'lib/backbone.js'
    ], 'js/bundle.js'

    // system-dependent order
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

    # or simply
    task 'watch', ->
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

## Tips

#### Disable the JS minifier during development

    task 'watch', ->
        # pass code through unchanged so you can
        # see useful line numbers when debugging
        flour.minifiers['.js'] = (file, cb) -> cb file.buffer

        watch 'scripts/*.coffee', -> invoke 'build'

#### Pre-compile Hogan templates

    flour.compilers['mustache'] = (file, cb) ->
        hogan = require 'hogan.js'
        file.read (code) ->
            cb "App.templates['#{file.base}']=${hogan.compile code, asString: true};"

    task 'build:templates', ->
        bundle 'views/*.mustache', 'resources/views.js'

## Why use flour?

While Grunt, brewerjs, H5BP-build-script, Yeoman and other similar projects have the same (and some more advanced) capabilities, they are increasingly complex to setup.

The goal of Flour is to provide a small and simple API that caters for the most common build tasks, without requiring you to adjust your project structure, install command-line tools or create long configuration files.

#### TODO:
- tests
- figure out how to magically bundle hogan templates
