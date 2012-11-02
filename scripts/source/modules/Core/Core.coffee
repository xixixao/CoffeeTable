# Core
# ----
#
# Encompasses core features:
# - erasing output
# - displaying help
# - dumping the compiled source
define [], () ->
  (TT) ->
# - erase
# - help
# - dump
  matchCommand: (commandSource) ->
    match = ""

    sc = (kw...) -> 
      match = source.match new RegExp "^\\s*(#{kw.join('|')})\\b\\s*"          

    if sc "dump", "d" then TT.Output.displayResult TT.compileSource()
    else if sc "erase", "e"  then TT.Output.eraseDisplay()