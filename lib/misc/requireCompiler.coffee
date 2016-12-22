# This is a simple helper function that you call to require a compiler. This is useful for making sure a compiler is installed and activated, otherwise it shows an error.
module.exports =
  (compiler, feature) ->
    unless compiler
      atom.notifications.addError "#{feature} cannot work without a compatable compiler."
      return false
    console.log(compiler)
    return true
