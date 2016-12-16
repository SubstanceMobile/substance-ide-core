{Disposable} = require 'atom'
module.exports =

  init: ->
    return new Disposable => @cleanup() # Return a disposable for this object

  cleanup: ->
