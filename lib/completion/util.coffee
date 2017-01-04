importer = require '../misc/importer'
module.exports =
  create: (out) -> (display, snippet, type, left, right, doc, docMore) =>
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
  simplifyName: (type) -> # Make known types human-readable
    if type.endsWith "[]" # If this is an array, cut off the ending and pass it through the reader.
      type = type.slice 0, -2
      array = true
    if type.includes("$")
      split = type.split '$' # Get an array of all types
      return([@simplifyName(split[0]), @simplifyName(split[1])].join(" \u2BA1 ")) # Pretty format this.
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
