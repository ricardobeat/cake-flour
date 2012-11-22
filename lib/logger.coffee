# Logger object
# -------------
# Allows logging to be disabled or routed to a file

logger = {}

methods = [
    'assert', 'clear', 'count', 'debug', 'dir', 'dirxml', 'error',
    'exception', 'group', 'groupCollapsed', 'groupEnd', 'info', 'log',
    'markTimeline', 'profile', 'profileEnd', 'table', 'time', 'timeEnd',
    'timeStamp', 'trace', 'warn'
]

methods.forEach (method) ->
    logger[method] = =>
        return if logger.silent
        console[method].apply console, Array::slice.call arguments

module.exports = logger