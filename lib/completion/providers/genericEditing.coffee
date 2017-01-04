model = require '../../model/model'
scope = require '../../scope/scope'
state = require '../state'
module.exports =
  selector: '.source.kotlin' # Work on Kotlin files
  disableForSelector: '.source.kotlin .comment, .source.kotlin .string'
  inclusionPriority: 2
  excludeLowerPriority: false
  suggestionPriority: 4

  getPrefix: (editor, bufferPosition) ->
    preDot = /\w+?(?=\..+?$|\.+$)/g # This is everything before the dot
    klass = /(?:[A-Z])\w*\(\);?$/g # This is a class declaration
    #func = /^(?![A-Z])\w*\(\);?/g # This is a function call

    return {var: true, query: editor.buffer.lines[bufferPosition.row].match(preDot)?[0]}

  getSuggestions: ({prefix, editor, bufferPosition}) ->
    context = @getPrefix(editor, bufferPosition)
    new Promise (resolve) ->
      try
        if context.var
          access = model.getAccessableForVariable(scope.findScope().uuid, context.query)
        else
          #access = model.getAccessable(model.lookup(context.query)[0])
      catch e
      if access
        state.supress()
      else
        state.depress()
        resolve()

      out = []
      create = require('../util').create(out)
      @simplifyName = require('../util').simplifyName

      for val in access.fields
        type = if val.mutable then 'variable' else 'value'
        create val.name, val.name, type, simplifyName val.type
      for fun in access.functions.concat(access.overrideableFunctions)
        args = []
        argsSnip = []
        for arg, i in fun.arguments # Process the arguments
          simple = simplifyName arg
          argsSnip.push "${#{i + 1}:#{simple}}"
          args.push simple
        create "#{fun.name}(#{args.join ','})", # Create the provider
          "#{fun.name}(#{argsSnip.join ', '})",
          'function',
          simplifyName fun.return
      resolve out.filter((obj) -> return obj.displayText.includes(prefix))

  onDidInsertSuggestion: ({editor, triggerPosition, suggestion}) ->
