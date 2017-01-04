scopeAccessable = require './providers/scopeAccessable', # For finding what the current class has access to, the context being edited
classes = require './providers/classes', # For finding classes that are not imported
genericEditing = require './providers/genericEditing' # This is for situations like `someClass.{Request access}`
module.exports = [scopeAccessable, classes, genericEditing]
