task 'minify', ->
    minify 'styles/*.css', 'build/styles/*'
    minify 'scripts/*.js', 'build/scripts/*'