flour  = require '../../flour'
should = require 'should'

flour.silent()

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
