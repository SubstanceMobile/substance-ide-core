# This class attempts to find the scope of the current cursor position.
{Disposable, Range, Point} = require 'atom'
importer = require "../misc/importer"
lookup = require("../model/model").lookup
module.exports =

  prependPackage: (editor, to) ->
    importer.getPackage(editor) + ".#{to}"

  findScope: () ->
    editor = atom.workspace.getActiveTextEditor()
    scope = {type: @prependPackage(editor, "PACKAGE"), name: "PACKAGE", package: importer.getPackage(editor), pos: new Point(0, 0)}

    unpairedEndBrackets = 0
    startRegex = /{/g
    closeRexex = /}/g
    combinedRegex = /[{}]/g

    editor.backwardsScanInBufferRange combinedRegex, new Range([0, 0], editor.getCursorBufferPosition()), (result) =>
      line = editor.getBuffer().getLines()[result.range.end.row]
      return if line.match(/.*\/\/.*/g) # If the bracket has a comment

      if result.matchText.match closeRexex # We have hit a "}", so tell the system that the next "{" that it sees belongs to this.
        unpairedEndBrackets++
      else if result.matchText.match startRegex # We have hit a "{", so get rid of one unclosed "}"
        unpairedEndBrackets--
        console.log "Hit open", unpairedEndBrackets, result
        if (unpairedEndBrackets < 0)
          result.stop()
          return unless ((line.match(/^(\S*class|.*object \:)/g)?[0] ? "") isnt "")
          # If we have no unpaired end tags, AND we have an opening bracket, AND we have a valid scope, return.
          cls = "unknown"
          text = line.match(/(\w*\.)*?[A-Z]\w*(?=(?:\(.*\))?\s?(\s?:\s?.*)?[\s?(?:\n{){]}?$)/g)[0]
          if line.match(/^\S*class/) # This is a local class in this file. Get the full provided name
            cls = @prependPackage(editor, text)
            clsName = text
            pkg = importer.getPackage(editor)
          else if text.match(/(\w*\.)/) # If this is an object, check if we have the package name
            cls = importer.search(text) ? text
            clsName = importer.denamespace(cls)
            pkg = importer.package(cls)
          else # If we don't have the package name, scan the imports
            cls = importer.search(text)
            clsName = importer.denamespace(cls)
            pkg = importer.package(cls)

          scope = {type: cls, name: clsName, package: pkg, pos: result.range.end, uuid: lookup(cls)[0]?.id}
     scope

  init: (composite) ->
    return new Disposable => @cleanup() # Return a disposable for this object

  cleanup: ->
