{CompositeDisposable} = require 'atom'
module.exports =
  config: require './config' # Enable settings

  provideCodeCompletion: -> require './completion/provider'

  activate: ->
    @session = new CompositeDisposable

    @session.add require('./completion/completer').init(),
      require('./format/prettyprinter').init(),
      require('./lint/linter').init(),
      require('./model/model').init(),
      require('./refactoring/refactorer').init(),
      require('./scope/scope').init()

  deactivate: ->
    @session.dispose()
