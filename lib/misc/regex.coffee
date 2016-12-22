module.exports = # This file contains many RegEx combiniations
  Ayy: /ayy/g

  # Properties
  Var: /var \w* ?:? ?\w* ?=? ?.*/
  Val: /val \w* ?:? ?\w* ?=? ?.*/
  VarVal: /(var|val) \w* ?:? ?\w* ?=? ?.*/
  # Refine:
  VarValSig: /^.*(?=  ?=.*$)/
  PropName: /\w* ?(?=  ?:.*$)/
  PropType: /\w+(?= ?(?:= ?.*)?$)/
  PropMutable: /val(?= ?\w* ?  ?:.*$)/
  PropHasValue: /(var|val) \w* ?:? ?\w* ?= ?.*/

  # Functions

  # Arguments
  # Arg:
  # ArgSig:
  # ArgName:
  # ArgType:
  # ArgSpecialHead
  # ArgDefault:
