decompile = require 'jdjs'
path = require 'path'
fs = require 'fs-plus'
importer = require '../../misc/importer'
indexer = require '../../model/legacy/indexer'

module.exports =
  selector: '.source.kotlin' # Work on Kotlin files
  disableForSelector: '.source.kotlin .comment, .source.kotlin .string'
  inclusionPriority: 1
  excludeLowerPriority: true
  suggestionPriority: 1

  getPrefix: (editor, bufferPosition) ->
    line = editor.getTextInRange([[bufferPosition.row, 0], bufferPosition]).trim()

    preDot = /.+?(?=\..+?$|\.+$)/g # This is everything before the dot
    dotType = /(?:(?![a-z])\w*\(\);?)|(?:(?![A-Z])\w*\(\);?)/g
    klass = /^(?![a-z])\w*\(\);?/g # This is a class declaration
    func = /^(?![A-Z])\w*\(\);?/g # This is a function call

    dotScopes = line.trim().match(preDot)
    return '' unless dotScopes
    scopes = dotScopes[dotScopes.length - 1].match(dotType)
    return '' unless scopes
    scope = scopes[scopes?.length - 1] # Get the class (or function return type) we are working with

    # Find out if this is a class or a function
    if scope.match(klass)?
      type = 'class'
    # else if scope.match(func)?
      # Coming soon

    return [type, scope]

  getSuggestions: ({editor, bufferPosition}) ->
    scope = @getPrefix(editor, bufferPosition)
    prefix = scope[1]
    # Can return a promise, an array of suggestions, or null.
    new Promise (resolve) ->
      # Create a suggestion and add it to the array
      out = []
      create = (display, snippet, type, left, right, doc, docMore) =>
        out.push {
          displayText: display
          snippet: snippet
          type: type
          leftLabel: left
          rightLabel: right
          description: doc
          descriptionMoreUrl: docMore
        }
        return out.length - 1
      simplifyName = (type) -> # Make known types human-readable
        if type.endsWith "[]" # If this is an array, cut off the ending and pass it through the reader.
          type = type.slice 0, -2
          array = true
        if type.includes("$")
          split = type.split '$' # Get an array of all types
          return([simplifyName(split[0]),simplifyName(split[1])].join(" \u2BA1 ")) # Pretty format this.
        simple = importer.denamespace(type) # Prepare for if the switch function does nothing, have a default value
        type = simple # Make sure the type is denamespaced
        switch type # Converting primitives and some renamed classes
          when 'boolean'
            simple = 'Boolean'
          when 'byte'
            simple = 'Byte'
          when 'char'
            simple = 'Char'
          when 'short'
            simple = 'Short'
          when 'int', "Integer"
            simple = 'Int'
          when 'long'
            simple = 'Long'
          when 'float'
            simple = 'Float'
          when 'double'
            simple = 'Double'
          when "Function0", "Function1",  "Function2", "Function3", "Function4", "Function5", "Function6", "Function7", "Function8", "Function9"
            simple = 'Lambda'
          when 'void'
            simple = 'Unit'
          when 'Object'
            simple = 'Any'
        if array # If this is an array, print it as an array.
          return "Array<#{simple}>"
        return simple

      # Calculate the scope
      scopes = indexer.get(scope)

      for scope in scopes # For each scope in the index
        for fun in scope.functions # Functions processing
          unless fun.private
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
        for val in scope.fields # Feilds processing
          unless val.private
            create val.name, val.name, if val.mutable then 'variable' else 'value', simplifyName val.type
        for cls in scope.classes # Classes processing
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

      # include = (text) => "#{text}".toLowerCase().includes prefix.toLowerCase()*
      # filtered = out.filter (one) =>
      #   include one.displayText or include one.leftLabel or include one.rightLabel or include one.description
      # console.log filtered
      # resolve(filtered)
      resolve out

  onDidInsertSuggestion: ({editor, triggerPosition, suggestion}) ->
    if suggestion.type is 'class'
      importer.addImport(suggestion.klass)

  dispose: -> # Cleanup
