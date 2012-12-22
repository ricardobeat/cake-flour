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

logger.fail = (what, file, e) ->
    logger.error "Error #{what}".red.inverse, file?.toString()
    if e.type and e.filename
        logger.error "[L#{e.line}:C#{e.column}]".yellow,
            "#{e.type} error".yellow
            "in #{e.filename}:".grey
            e.message
    else
        logger.error [e.type].toString().yellow, [e.message].toString().grey

module.exports = logger