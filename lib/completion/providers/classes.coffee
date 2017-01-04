model = require '../../model/model'
scope = require '../../scope/scope'
importer = require '../../misc/importer'
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

      #for cls in access.classes TODO
      for cls in require('../../model/legacy/indexer').get()[0].classes
        unless cls.private or (cls.name.endsWith "PACKAGE")
          simple = simplifyName cls.name
          args = []
          argsSnip = []
          for arg, i in cls.args # Process the arguments
            simple = simplifyName arg
            argsSnip.push "${#{i + 1}:#{simple}}"
            args.push simple
          objPos = create "#{simple}(#{args.join ','})",
            "#{simple}(#{argsSnip.join ', '})",
            'class'
            simplifyName cls.super
          out[objPos].klass = cls.name

      resolve out.filter((obj) -> return (obj.displayText.includes(prefix)) or (obj.klass.startsWithg))

  onDidInsertSuggestion: ({editor, triggerPosition, suggestion}) ->
    importer.addImport(suggestion.klass)
