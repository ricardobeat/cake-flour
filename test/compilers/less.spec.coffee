flour  = require '../../flour'
should = require 'should'

flour.silent()

describe 'LESS compiler', ->

    input_file  = "#{dir.sources}/compile.less"
    output_file = "#{dir.temp}/compile.css"

    it 'should compile LESS and return the output', (done) ->
        flour.compile input_file, (output) ->
            output.should.include '.one .two'
            done()

    it 'should compile LESS to a file', (done) ->
        flour.compile input_file, output_file, ->
            readFile(output_file).should.include '.one .two{color' # compressed by default
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

    it 'should compile LESS with yui compression enabled', (done) ->
        flour.compilers.less.yuicompress = true
        flour.compile input_file, (output) ->
            output.should.include '.one .two{color:#abcdef}'
            done()
