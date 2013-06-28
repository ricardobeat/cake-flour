should = require 'should'
fs     = require 'fs'
path   = require 'path'

flour  = require '../flour'
File   = require '../lib/file'

global.readFile = (file) -> fs.readFileSync(file).toString()
global.copyFile = (file, out) -> fs.writeFileSync out, readFile file

global.dir =
    sources: 'test/sources'
    temp: 'test/temp'

flour.silent()

describe 'Flour', ->

    it 'should exist', ->
        should.exist flour

    it 'should expose a compile method', ->
        flour.compile.should.be.a('function')

    it 'should expose a minify method', ->
        flour.minify.should.be.a('function')

    it 'should expose a lint method', ->
        flour.lint.should.be.a('function')

    it 'should expose a bundle method', ->
        flour.bundle.should.be.a('function')

    it 'should expose a watch method', ->
        flour.bundle.should.be.a('function')


describe 'Bundle', ->

    sources_js  = "#{dir.sources}/bundle-js"
    sources_cs  = "#{dir.sources}/bundle-coffee"
    output_file = "#{dir.temp}/bundled.js"
    output_js   = "#{dir.temp}/bundled-js.js"

    it 'should minify and join an array of JS files', (done) ->
        flour.bundle [
            "#{sources_js}/jsbundle1.js"
            "#{sources_js}/jsbundle2.js"
        ], output_js,  ->
            contents = readFile output_js
            contents.should.include 'function bundle1()'
            contents.should.include 'function bundle2()'
            done()

    it 'should compile, minify and join an array of coffeescript files', (done) ->
        flour.bundle [
            "#{sources_cs}/bundle1.coffee"
            "#{sources_cs}/bundle2.coffee"
        ], output_file,  ->
            contents = readFile output_file
            contents.should.include 'bundle1=function()'
            contents.should.include 'bundle2=function()'
            done()

    it 'should compile and minify a single file', (done) ->
        flour.bundle "#{sources_cs}/bundle1.coffee", output_file,  ->
            readFile(output_file).should.include 'bundle1=function()'
            done()

    it 'should accept a simple wildcard path', (done) ->
        flour.bundle "#{sources_cs}/*.coffee", output_file, ->
            contents = readFile output_file
            contents.should.include 'bundle1=function('
            contents.should.include 'bundle2=function('
            done()

    it 'should accept a complex wildcard path', (done) ->
        flour.bundle "#{sources_cs}/bun*1.coffee", output_file, ->
            contents = readFile output_file
            contents.should.include 'bundle1=function('
            contents.should.not.include 'bundle2=function('
            done()

    it 'should accept a more complex wildcard path', (done) ->
        flour.bundle "#{sources_cs}/bun*1.+(coffee|js)", output_file, ->
            contents = readFile output_file
            contents.should.include 'bundle1=function('
            contents.should.not.include 'bundle2=function('
            done()

    it 'should accept a directory path', (done) ->
        flour.bundle "#{sources_cs}", output_file, ->
            contents = readFile output_file
            contents.should.include 'bundle1=function('
            contents.should.include 'bundle2=function('
            done()

    it 'should accept a directory path with a trailing slash', (done) ->
        flour.bundle "#{sources_cs}/", output_file, ->
            contents = readFile output_file
            contents.should.include 'bundle1=function('
            contents.should.include 'bundle2=function('
            done()

    it 'should wrap compiled code', (done) ->
        flour.bundle "#{sources_js}/*", {
            wrap: ['TEST(', ');']
        }, output_file, ->
            contents = readFile output_file
            contents.should.include 'TEST(function(){return 1})'
            done()

    it 'should add before/after strings to bundle', (done) ->
        flour.minifiers.disable()
        options =
            before: '(function(n,y,c){'
            after: '}("wrap"));'
        flour.bundle "#{sources_js}/*", options, output_file, ->
            contents = readFile output_file
            contents.should.include options.before
            contents.should.include options.after
            flour.minifiers.enable()
            done()

    it 'should support a globstar pattern', (done) ->
        flour.bundle "#{dir.sources}/**/*.coffee", output_file, ->
            contents = readFile output_file
            contents.should.include 'bundle1=function('
            contents.should.include 'bundle2=function('
            done()

describe 'flour.get', (contents) ->

    s1 = "#{dir.sources}/compile.coffee"
    s2 = "#{dir.sources}/compile.styl"

    lintall = "#{dir.sources}/lint/*"
    lint1   = "#{dir.sources}/lint/lint-1.js"
    lint2   = "#{dir.sources}/lint/lint-1.js"

    it 'should return an instance of File', (done) ->
        flour.get s1, (f) ->
            this.should.be.an.instanceof File
            done()

    it 'should return a single file\'s contents', (done) ->
        flour.get s1, (contents) ->
            contents.should.equal readFile(s1)
            done()

    it 'should return multiple file\'s contents', (done) ->
        flour.get [s1, s2], (res) ->
            # contents should be available at both index and filename keys
            should.exist res[0]
            should.exist res[1]
            res[0].should.equal readFile(s1)
            res[1].should.equal readFile(s2)

            should.exist res[s1]
            should.exist res[s2]
            res[s1].should.equal readFile(s1)
            res[s2].should.equal readFile(s2)

            done()

    it 'should accept complex paths/patterns', (done) ->
        flour.get lintall, (res) ->
            should.exist res[lint1]
            should.exist res[lint2]
            res[lint1].should.equal readFile(lint1)
            res[lint2].should.equal readFile(lint2)
            done()

describe 'File path handling', ->

    m1 = "#{dir.temp}/multi1.js"
    m2 = "#{dir.temp}/multi2.js"

    copyFile "#{dir.sources}/multiple/multi1.coffee", "#{dir.temp}/multi1.coffee"
    copyFile "#{dir.sources}/multiple/multi2.coffee", "#{dir.temp}/multi2.coffee"

    checkMultipleFiles = (done) -> ->
        should.exist fs.existsSync m1
        readFile(m1).should.include 'multiple 1'
        should.exist fs.existsSync m2
        readFile(m2).should.include 'multiple 2'
        fs.unlinkSync m1
        fs.unlinkSync m2
        done()

    it 'should compile multiple files (array)', (done) ->
        flour.compile [
            "#{dir.sources}/multiple/multi1.coffee"
            "#{dir.sources}/multiple/multi2.coffee"
        ], "#{dir.temp}", checkMultipleFiles done

    it 'should compile multiple files (*)', (done) ->
        flour.compile "#{dir.temp}/multi*.coffee", "*", checkMultipleFiles done

    it 'should compile multiple files (*), arguments in the the right order', (done) ->
        flour.compile "#{dir.temp}/multi*.coffee", "*", (files) ->
            files['multi1.coffee'].should.be.a 'object'
            files['multi2.coffee'].should.be.a 'object'
            files['multi1.coffee'].output.should.include 'multiple 1'
            files['multi2.coffee'].output.should.include 'multiple 2'
            done()

    it 'should compile multiple files (folder)', (done) ->
        flour.compile "#{dir.sources}/multiple/*.coffee", "#{dir.temp}", checkMultipleFiles done

    it 'should compile multiple files (folder/)', (done) ->
        flour.compile "#{dir.sources}/multiple/*.coffee", "#{dir.temp}/", checkMultipleFiles done

    it 'should compile multiple files (folder/*)', (done) ->
        flour.compile "#{dir.sources}/multiple/*.coffee", "#{dir.temp}/*", checkMultipleFiles done

    it 'should compile multiple files (null)', (done) ->
        flour.compile "#{dir.temp}/multi*.coffee", null, checkMultipleFiles done

    it 'should bundle multiple files using patterns', (done) ->
        output = "#{dir.temp}/bundled-pattern.js"
        flour.bundle [
            "#{dir.sources}/bundle-coffee/*.coffee"
            "#{dir.sources}/multiple/*.coffee"
        ], output, ->
            should.exist fs.existsSync output
            contents = readFile(output)
            contents.should.include 'x.bundle1=function'
            contents.should.include 'multiple 1'
            done()

    it 'should lint multiple files', (done) ->
        flour.lint "#{dir.sources}/lint/*.js", (results) ->
            [a, b] = [results['lint-1.js'], results['lint-2.js']]
            should.exist a
            should.exist b
            should.equal a.passed, true
            should.equal b.passed, true
            should.equal a.errors.constructor, Array
            should.equal b.errors.constructor, Array
            done()

    it 'should create output dir if needed', (done) ->
        flour.compile "#{dir.sources}/compile.coffee", "#{dir.temp}/a/b/c/*", ->
            out = "#{dir.temp}/a/b/c/compile.js"
            should.exist fs.existsSync out
            readFile(out).should.include 'bacon = function'
            done()

requiretree = require 'require-tree'
requiretree('test/compilers')
requiretree('test/minifiers')
