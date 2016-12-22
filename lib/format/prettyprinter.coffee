{Disposable} = require 'atom'
module.exports =

  init: (composite) ->
    composite.add atom.commands.add 'atom-workspace',
      'prettyprinter:reformat-code': (event) => @reformat()

    return new Disposable => @cleanup() # Return a disposable for this object

  reformat: () ->
    atom.notifications.addSuccess "Feature coming soon"

  cleanup: ->
