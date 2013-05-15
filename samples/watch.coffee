task 'watch', ->
    watch 'sources/*.js', -> invoke 'build:source'
    watch 'styles/*', -> invoke 'build:styles'
    watch [
        'content/**/*.html'
        'views/*'
    ], -> invoke 'build:templates'