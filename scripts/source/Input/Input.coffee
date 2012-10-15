define [
  "cs!./CodeMirrorSetup"
], (CodeMirrorSetup) ->
  
  # Part handling CodeMirror setup and user input.  
  class Input extends EventDispatcher
    events:
      execute: true
      backHistory: true
      forwardHistory: true
      sourceAreaChanged: true

    initalize: ->
      @timeline = new TimeLine
      
      CodeMirrorSetup.initalize()

      CodeMirrorSetup.bind "commandLineKeyAction", (e, key) ->
        if e.type == "keyup"
          shouldStop = true
          switch key
            when "Enter"
              @trigger "execute"              
            when "Up"
              @trigger "backHistory"
            when "Down"
              @trigger "forwardHistory"          
            else
              shouldStop = false
          if shouldStop
            e.stop() 

      @propagate CodeMirrorSetup, "sourceChanged"
  
  new Input