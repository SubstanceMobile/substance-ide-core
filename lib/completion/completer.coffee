{Disposable} = require 'atom'
module.exports =

  init: (composite) ->

    return new Disposable => @cleanup() # Return a disposable for this object

  cleanup: ->
