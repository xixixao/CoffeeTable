require [
  "cs!./Input/Input"
  "cs!./Executioner"
  "cs!./Output"
], (Input, Executioner, Output)->

  class TeaTable
    constructor: ->
      Input.initalize()

      Executioner.compiler = @prepareCompiler IcedCoffeeScript, bare: on
      
      Input.bind "sourceChanged", ->
        @sourceAlreadyCompiled = no

      Input.bind "execute", ->  
        Executioner.executeCommand Input.command, @modules  

      Executioner.bind "error", (message) ->
        Output.displayError message

      Executioner.bind "result", (message) ->
        Output.displayResult message

    compileSource: ->
      unless @sourceAlreadyCompiled
        Executioner.compileSource Input.source
      Executioner.compiledSource

    prepareCompiler: (compiler, options) ->
      compiler.options: -> $.extend {}, options
      compiler

  # Initialize everything  
  new TeaTable
