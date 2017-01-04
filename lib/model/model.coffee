{Disposable, CompositeDisposable} = require 'atom'
indexer = require './legacy/indexer'
module.exports =

  ##############################################
  # Lifecycle
  ##############################################

  init: (@composite, @compiler) ->
    return new Disposable unless require('../misc/requireCompiler')(@compiler, "Code Index") # Check for compiler

    @runningDisposable = new Disposable
    @stoppedIndexing()

    @composite.add atom.commands.add "atom-workspace",
      'indexer:invalidate-caches': (event) => indexer.invalidateCaches()
    @composite.add @runningDisposable

    return new Disposable => @cleanup() # Return a disposable for this object

  startedIndexing: ->
    @runningDisposable.dispose()
    @runningDisposable = new Disposable
    @runningDisposable = atom.commands.add "atom-workspace",
      'indexer:stop-indexing': (event) => @cleanup()
    @composite.add @runningDisposable

  stoppedIndexing: ->
    @runningDisposable.dispose()
    @runningDisposable = new Disposable
    @runningDisposable = atom.commands.add "atom-workspace",
      'indexer:index': (event) =>
        @startedIndexing()
        @indexerTask?.kill()
        if indexer.canIndex()
          @compiler.runTask(['indexProject', 'indexLibs'], true, true)
          @indexerTask = @compiler.proc # Save the process here, so if another build task is run this will stay alive and can still be controlled.
          indexer.index()
    @composite.add @runningDisposable

  cleanup: ->
    @stoppedIndexing()
    @indexerTask?.kill()
    indexer.stopListening()
    delete @indexerTask

  ##############################################
  # Search
  ##############################################

  lookup: (klass) ->
    (indexer.get()[0]?.classes ? []).filter (obj) -> return obj.name.startsWith klass

  lookupById: (id) -> # Find a class by its id
    (indexer.get()[0]?.classes ? []).filter (obj) -> return obj.id is id

  isPackage: (id) -> # Check whether or not a id is a package or a class (to check if a class is nested or not)
    ((indexer.get()[0]?.packages ? []).filter (obj) -> return obj.id is id).length isnt 0

  ##############################################
  # Scope
  ##############################################

  internalGetAccessable: (id, out, allowPrivate = false) -> # Should only be used internally
    for fun in indexer.get()[0].functions ? [] # Get all of the accessable function
      out[if fun.final then "functions" else "overrideableFunctions"].push fun if (fun.class is id) and ((not fun.private) or allowPrivate)
    for field in indexer.get()[0].fields ? [] # Get all of the accessable fields
      out.fields.push field if (field.class is id) and ((not field.private) or allowPrivate)

  getAccessable: (id, allowPrivate = true) -> # Takes the id of a class, and spits out everything this class has access to
    # if @isPackage id TODO: Impliment support for this eventually, since packages matter too
    klass = @lookupById(id)[0]
    out = {}
    out.fields = [] # The fields that can only be accessed, but not overriden
    out.functions = [] # The functions that can only be called
    out.overrideableFunctions = [] # Functions that can be overriden. Scope should be queried on whether or not these should be called or overriden

    # It is safe to import a class and its subclass right off the bat, since those will always be valid
    @internalGetAccessable(id, out, allowPrivate)
    @internalGetAccessable(superId, out) if (superId = @lookup(klass.super)[0]?.id)

    # If this class isn't in a package (it is nested), import the things it is nested in
    @internalGetAccessable(klass.in, out) unless @isPackage klass.in

    return out

  getAccessableForVariable: (id, varName) -> # Look up what a certain variable has access to (used in varName.{ACCESS})
    @getAccessable(@lookup(@getAccessable(id).fields.filter((obj) -> return obj.name is varName)[0].type)[0].id, false)
