flour  = require '../../flour'
should = require 'should'

flour.silent()

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
