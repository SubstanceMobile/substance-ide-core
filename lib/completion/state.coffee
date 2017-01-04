module.exports =
  supress: () -> @supressing = true

  depress: () -> @supressing = false

  supressed: () -> @supressing ? false
