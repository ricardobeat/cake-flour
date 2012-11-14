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

describe 'Compiler', ->

    it 'should compile CoffeeScript', (done) ->
        flour.compile 'test/sources/test.coffee', (output) ->
            output.should.include 'bacon = function'
            done()

    it 'should compile CoffeeScript to a file', (done) ->
        input  = 'test/sources/test.coffee'
        output = 'test/temp/test.js'
        flour.compile input, output
        contents = fs.readFileSync(output).toString()
        contents.should.include 'bacon = function'
        done()
