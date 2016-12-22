{CompositeDisposable} = require 'atom'
module.exports =
  config: require './config' # Enable settings

  provideCodeCompletion: -> require './completion/provider'

  activate: ->
    @session = new CompositeDisposable

    @session.add require('./completion/completer').init(@session),
      require('./format/prettyprinter').init(@session),
      require('./lint/linter').init(@session),
      require('./refactoring/refactorer').init(@session),
      require('./scope/scope').init(@session)

  handleCompiler: (compiler) ->
    @session.add require('./model/model').init(@session, compiler)

  deactivate: ->
    @session.dispose()
