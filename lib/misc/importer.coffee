PackageNameRegex = /package\s+([^\s+]+)/
ImportRegex = /import\s+([^\s+]+)/g
index = require "../model/model"
module.exports = KotlinImporter =

  getPackage: (editor) ->
    out = ''
    editor.scan PackageNameRegex, ({match}) ->
      out = match[1]
    return out

  getEndPoint: (editor, regex) ->
    pt = undefined
    editor.scan regex, ({range}) ->
      pt = range.end.traverse [1, 0]
    return pt

  package: (klass) ->
    klass.substr 0, klass.lastIndexOf '.'

  denamespace: (klass) ->
    klass.substr klass.lastIndexOf('.') + 1

  imported: (editor, klass) ->
    #return false if output[0] is undefined
    for imp in @getImports(editor)
      if imp is klass then return true
      if @denamespace(imp) is "*" # Wildcard import
        if @package imp is @package klass then return true
    return false

  addImport: (klass) ->
    editor = atom.workspace.getActiveTextEditor()
    imp = klass

    subClassPos = klass.indexOf('$') # Seperate out nested classes
    if subClassPos isnt -1 then imp = klass.substr(0, subClassPos)

    return if @imported(editor, imp) # Return if we are already imported

    impPkg = @package(imp) # If we are in the same package, why import?
    if impPkg is @getPackage(editor) or impPkg is "java.lang" then return

    # Calculate where to add the import
    point = @getEndPoint(editor, ImportRegex)
    unless point then point = @getEndPoint(editor, PackageNameRegex)
    unless point then point = [0, 0]

    editor.getBuffer().insert(point, "import #{imp}\n") # Add the import

  getImports: (editor) ->
    output = []
    editor.scan ImportRegex, ({match}) ->
      output.push match[1]
    return output

  search: (klass) -> # Searches for the class in the imports
    editor = atom.workspace.getActiveTextEditor()
    imports = @getImports(editor).sort (imp) ->
      return 1 if imp.endsWith "*"
      return 0
    for imp in imports
      unless imp.endsWith "*" # If this isn't a wildcard import
        return imp if imp.endsWith(klass) # Check for normal imports
      else
        classes = index.lookup(@package(imp)) # Get all of the classes with this package
        for cls in classes
          return cls.name if cls.name.endsWith(klass)
