flour  = require '../../flour'
should = require 'should'
fs     = require 'fs'

flour.silent()

describe 'CoffeeScript compiler', ->

    input_file  = "#{dir.sources}/compile.coffee"
    output_file = "#{dir.temp}/compile.js"

    it 'should compile CoffeeScript and return the output', (done) ->
        flour.compile input_file, (output) ->
            output.should.include 'bacon = function'
            done()

    it 'should compile CoffeeScript to a file', (done) ->
        flour.compile input_file, output_file, ->
            readFile(output_file).should.include 'bacon = function'
            done()

    it 'should compile CoffeeScript to a file && return the output', (done) ->
        flour.compile input_file, output_file, (res) ->
            should.exist fs.existsSync output_file
            res.should.include 'bacon = function'
            done()
