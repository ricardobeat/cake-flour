should = require 'should'
fs     = require 'fs'
path   = require 'path'

flour  = require '../flour'

readFile = (file) -> fs.readFileSync(file).toString()

dir =
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

describe 'CoffeeScript compiler', ->

    input_file  = "#{dir.sources}/compile.coffee"
    output_file = "#{dir.temp}/compile.js"

    it 'should compile CoffeeScript and return the output', (done) ->
        flour.compile input_file, (output) ->
            output.should.include 'bacon = function'
            done()

    it 'should compile CoffeeScript to a file', (done) ->
        flour.compile input_file, output_file
        readFile(output_file).should.include 'bacon = function'
        done()

    it 'should compile CoffeeScript to a file && return the output', (done) ->
        flour.compile input_file, output_file, (res) ->
            should.exist fs.existsSync output_file
            res.should.include 'bacon = function'
            done()

describe 'LESS compiler', ->

    input_file  = "#{dir.sources}/compile.less"
    output_file = "#{dir.temp}/compile.css"

    it 'should compile LESS and return the output', (done) ->
        flour.compile input_file, (output) ->
            output.should.include '.one .two'
            done()

    it 'should compile LESS to a file', (done) ->
        flour.compile input_file, output_file, ->
            readFile(output_file).should.include '.one .two'
            done()

    it 'should compile LESS to a file && return the output', (done) ->
        flour.compile input_file, output_file, (res) ->
            readFile(output_file).should.include '.one .two'
            res.should.include '.one .two'
            done()

    it 'should compile LESS with compression disabled', (done) ->
        flour.compilers.less.compress = false
        flour.compile input_file, (output) ->
            output.should.include '.one .two {\n  color: #abcdef;\n}'
            done()


describe 'Stylus compiler', ->

    input_file  = "#{dir.sources}/compile.styl"
    output_file = "#{dir.temp}/compile.css"

    it 'should compile Stylus and return the output', (done) ->
        flour.compile input_file, (output) ->
            output.should.include '.one .two'
            done()

    it 'should compile Stylus to a file', (done) ->
        flour.compile input_file, output_file, ->
            readFile(output_file).should.include '.one .two'
            done()

    it 'should compile Stylus to a file && return the output', (done) ->
        flour.compile input_file, output_file, (res) ->
            readFile(output_file).should.include '.one .two'
            res.should.include '.one .two'
            done()

    it 'should compile Stylus with compression disabled', (done) ->
        flour.compilers.styl.compress = false
        flour.compile input_file, (output) ->
            output.should.include '.one .two {\n  color: #abcdef;\n}'
            done()


describe 'JS minifier', ->

    input_file  = "#{dir.sources}/minify.js"
    output_file = "#{dir.temp}/minify.min.js"

    it 'should minify javascript and return the output', (done) ->
        flour.minify input_file, (output) ->
            output.should.include 'function test(){return'
            done()

    it 'should minify javascript to a file', (done) ->
        flour.minify input_file, output_file, ->
            readFile(output_file).should.include 'function test(){return'
            done()


describe 'CSS minifier', ->

    input_file  = "#{dir.sources}/minify.css"
    output_file = "#{dir.temp}/minify.min.css"

    it 'should minify css and return the output', (done) ->
        flour.minify input_file, (output) ->
            output.should.include 'body,p{color:red}'
            done()

    it 'should minify css to a file', (done) ->
        flour.minify input_file, output_file, ->
            readFile(output_file).should.include 'body,p{color:red}'
            done()

describe 'Bundle', ->

    sources_js  = "#{dir.sources}/bundle-js"
    sources_cs  = "#{dir.sources}/bundle-coffee"
    output_file = "#{dir.temp}/bundled.js"

    it 'should minify and join an array of JS files', (done) ->
        flour.bundle [
            "#{sources_js}/bundle1.js"
            "#{sources_js}/bundle2.js"
        ], output_file,  ->
            contents = readFile output_file
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
