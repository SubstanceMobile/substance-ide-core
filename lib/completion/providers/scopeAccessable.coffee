model = require '../../model/model'
scope = require '../../scope/scope'
state = require '../state'
module.exports =
  selector: '.source.kotlin' # Work on Kotlin files
  disableForSelector: '.source.kotlin .comment, .source.kotlin .string'
  inclusionPriority: 1
  excludeLowerPriority: true
  suggestionPriority: 2

  getSuggestions: ({prefix}) ->
    new Promise (resolve) ->
      resolve() if require('../state').supressed()
      out = []
      create = require('../util').create(out)
      @simplifyName = require('../util').simplifyName
      access = model.getAccessable(scope.findScope().uuid)

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
