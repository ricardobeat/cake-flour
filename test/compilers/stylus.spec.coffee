flour  = require '../../flour'
should = require 'should'

flour.silent()

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