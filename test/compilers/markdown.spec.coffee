flour  = require '../../flour'
should = require 'should'

flour.silent()

describe 'Markdown compiler', ->

    input_file  = "#{dir.sources}/simple.md"
    output_file = "#{dir.temp}/simple.html"

    it 'should compile markdown and return the output', (done) ->
        flour.compile input_file, (output) ->
            output.should.include """
                <h1>H1</h1>
                <p>Hello, paragraph.</p>
                <h2>H2</h2>
            """
            done()

    it 'should compile markdown to a file', (done) ->
        flour.compile input_file, output_file, ->
            readFile(output_file).should.include """
                <h1>H1</h1>
                <p>Hello, paragraph.</p>
                <h2>H2</h2>
            """
            done()
