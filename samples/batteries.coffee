flour = require 'flour'

task 'build:coffee', ->
    # Compile CoffeeScript
    compile 'app.coffee', 'app.js'
    # Minify CSS
    minify 'themes/obsidian.css', 'styles/theme.min.css'
    # Concat & minify
    bundle '*.js', 'everything.min.js'