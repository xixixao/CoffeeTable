
  
  toCommand = (command) ->
    commandPrefix = /^(< |:)/
    matched = command.match commandPrefix
    if matched
      command[matched[0].length..] 
    else 
      undefined
  
  executeCommand = (compiledSource, command, modules) ->
    unless source? and command?
      return
      
    if commandInput = @toCommand command
      for module in modules
        [success, match, handle] = module.matchCommand commandInput
        if success
          handle match
          break
    else
      try
        compiledCommand = Executioner.compile command
      catch error
        @trigger "error", "Command Line: " + error.message
        return
      try        
        result = @execute compiledSource + compiledCommand
      catch error
        @trigger "error", "Runtime: " + error
      Output.log result


  # Set up the compilation function, to run when you stop typing.
  compileSource = (source) ->
    compiledJS = ""
    try
      compiledJS = compiler.compile source, getCompilerOptions()
    catch error
      @trigger "error", "Compiler: " + error.message    
    