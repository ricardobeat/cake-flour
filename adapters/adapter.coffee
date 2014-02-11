
class Adapter
    constructor: (@adapters) ->
        @disabled = []
        for ext, adapter of @adapters
            @install ext, adapter

    install: (ext, adapter) ->
        Object.defineProperty @, ext,
            configurable: yes
            get: -> adapter if ext not in @disabled

    disable: (ext) ->
        if not ext then @disabled.push ext for ext of @adapters
        else @disabled.push ext

    enable: (ext) ->
        if not ext then @disabled = []
        else @disabled = @disabled.filter (e) -> e isnt ext


Adapter.getOptions = (self, defaults) ->
    options = {}
    options[key] = val for own key, val of self
    options[key] ?= val for own key, val of defaults
    return options

module.exports = Adapter