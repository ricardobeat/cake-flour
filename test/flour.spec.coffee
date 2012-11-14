should = require 'should'
fs     = require 'fs'

flour  = require '../flour'

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

    input_file  = 'test/sources/compile.coffee'
    output_file = 'test/temp/compile.js'

    it 'should compile CoffeeScript and return the output', (done) ->
        flour.compile input_file, (output) ->
            output.should.include 'bacon = function'
            done()

    it 'should compile CoffeeScript to a file', (done) ->
        
        flour.compile input_file, output_file
        contents = fs.readFileSync(output_file).toString()
        contents.should.include 'bacon = function'
        done()

    it 'should compile CoffeeScript to a file && return the output', (done) ->
        flour.compile input_file, output_file, (res) ->
            should.exist fs.existsSync output_file
            res.should.include 'bacon = function'
            done()

describe 'LESS compiler', ->

    input_file  = 'test/sources/compile.less'
    output_file = 'test/temp/compile.css'

    it 'should compile LESS and return the output', (done) ->
        flour.compile input_file, (output) ->
            output.should.include '.one .two'
            done()

    it 'should compile LESS to a file', (done) ->
        flour.compile input_file, output_file, (res) ->
            res.should.include '.one .two'
            done()

    it 'should compile LESS to a file && return the output', (done) ->
        flour.compile input_file, output_file, (res) ->
            res.should.include '.one .two'
            done()

    it 'should compile LESS with compression disabled', (done) ->
        flour.compilers.less.compress = false
        flour.compile input_file, (output) ->
            output.should.include '.one .two {\n  color: #abcdef;\n}'
            done()

describe 'Stylus compiler', ->

    input_file  = 'test/sources/compile.styl'
    output_file = 'test/temp/compile.css'

    it 'should compile Stylus and return the output', (done) ->
        flour.compile input_file, (output) ->
            output.should.include '.one .two'
            done()

    it 'should compile Stylus to a file', (done) ->
        flour.compile input_file, output_file, (res) ->
            res.should.include '.one .two'
            done()

    it 'should compile Stylus to a file && return the output', (done) ->
        flour.compile input_file, output_file, (res) ->
            res.should.include '.one .two'
            done()

    it 'should compile Stylus with compression disabled', (done) ->
        flour.compilers.styl.compress = false
        flour.compile input_file, (output) ->
            output.should.include '.one .two {\n  color: #abcdef;\n}'
            done()

describe 'JS minifier', ->

    input_file  = 'test/sources/compile.styl'
    output_file = 'test/temp/compile.css'

    it 'should compile Stylus and return the output', (done) ->
        flour.compile input_file, (output) ->
            output.should.include '.one .two'
            done()

    it 'should compile Stylus to a file', (done) ->
        flour.compile input_file, output_file, (res) ->
            res.should.include '.one .two'
            done()

    it 'should compile Stylus to a file && return the output', (done) ->
        flour.compile input_file, output_file, (res) ->
            res.should.include '.one .two'
            done()

    it 'should compile Stylus with compression disabled', (done) ->
        flour.compilers.styl.compress = false
        flour.compile input_file, (output) ->
            output.should.include '.one .two {\n  color: #abcdef;\n}'
            done()
