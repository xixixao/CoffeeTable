define [
  'lib/cm/codemirror'
], (CodeMirror) ->
  
  # Part which sets up the CodeMirror text areas and handles changing of focus.
  class CodeMirrorSetup extends EventDispatcher
    events:
      sourceChanged: true
      commandLineKeyUp: true
      sourceAreaKeyUp: true

    initialize: ->
      # Initialize CodeMirror
      # ---------------------

      CodeMirror.keyMap.commandLine =
        "Up": "doNothing"
        "Down": "doNothing"
        "PageUp": "doNothing"
        "PageDown": "doNothing"
        "Enter": "doNothing"
        fallthrough: "default"

      CodeMirror.commands.doNothing = (cm) -> true

      sourceArea = CodeMirror.fromTextArea $("#code").get(0),
        tabSize: 2
        indentUnit: 2
        lineNumbers: true
        extraKeys: "Tab": "indentMore", "Shift-Tab": "indentLess"
        onChange: (inst, e) -> 
          @trigger "sourceChanged", inst, e

      commandLine = CodeMirror.fromTextArea $("#code2").get(0),
        tabSize: 2
        indentUnit: 2
        keyMap: "commandLine"
        onKeyEvent: (inst, e) -> 
          if e.type == "keyup"
            @trigger "commandLineKeyUp", e, CodeMirror.keyNames[e.keyCode]

      # Editor Functionality
      # -------------------- 

      $(editor.getInputField()).keyup (e) ->
        @trigger "sourceAreaKeyUp", e, CodeMirror.keyNames[e.keyCode]

      # Switching focus on mouseenter and escape

      $('#wrapcmd .CodeMirror').mouseenter (e) ->
        commandLine.focus()

      $('#wrapcode .CodeMirror').mouseenter (e) ->
        sourceArea.focus()

      @bind "sourceAreaKeyUp", (e, key) ->
        if key == "Esc"
            commandLine.focus()

      @bind "commandLineKeyUp", (e, key) ->        
        if key == "Esc"
          sourceArea.focus()


      # Editor Sizing
      # -------------

      setMaxPreWidth = ($pre) ->
        $pre.css "max-width", ($(window).width() * 0.5 - 95) + "px"  

      resizeEditor = (e) ->
        $('#wrapcode .CodeMirror-scroll').css "max-height", ($(window).height() - 175) + "px"
        $('#rightColumn').css "max-height", ($(window).height() - 35) + "px"
        setMaxPreWidth $('#consoleSpace pre')

      resizeEditor()
      $(window).resize resizeEditor  

  new CodeMirrorSetup