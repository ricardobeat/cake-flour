errors =
    NOT_FOUND : "File not found."
    NO_MATCH  : "No files match."

for err, msg of errors
    module.exports[err] = (file) -> new Error "#{msg} (#{file})"