task 'build', ->
    compile 'layout.styl', 'layout.css' # Stylus
    compile 'layout.less', 'layout.css' # LESS
    compile 'layout.*', 'layout.css'    # either!