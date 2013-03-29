
class Adapter
    constructor: (@adapters) ->
        @disabled = []
        for ext, adapter of @adapters
            do (ext) =>
                Object.defineProperty @, ext,
                    get: -> @adapters[ext] if ext not in @disabled

    disable: (ext) ->
        if not ext then @disabled.push ext for ext of @adapters
        else @disabled.push ext

    enable: (ext) ->
        if not ext then @disabled = []
        else @disabled = @disabled.filter (e) -> e isnt ext

module.exports = Adapter