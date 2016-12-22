{Disposable} = require 'atom'
indexer = require './legacy/indexer'
module.exports =

  init: (composite, compiler) ->
    return new Disposable unless require('../misc/requireCompiler')(compiler, "Code Index") # Check for compiler

    composite.add atom.commands.add "atom-workspace",
      'indexer:index': (event) =>
        @indexerTask?.kill()
        if indexer.canIndex()
          compiler.runTask(['indexProject', 'indexLibs'], true)
          @indexerTask = compiler.proc # Save the process here, so if another build task is run this will stay alive and can still be controlled.
          indexer.index()
      'indexer:stop-indexing': (event) => @cleanup()
      'indexer:invalidate-caches': (event) => indexer.invalidateCaches()

    return new Disposable => @cleanup() # Return a disposable for this object

  lookup: (klass) ->
    (indexer.get()[0]?.classes ? []).filter (obj) =>
      return obj.name.startsWith klass

  cleanup: ->
    @indexerTask?.kill()
    indexer.stopListening()
    delete @indexerTask
