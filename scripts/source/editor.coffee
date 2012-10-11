require [
  'lib/jquery/jquery.cookie'
  'lib/jquery/jquery.animate-colors'
  'lib/cm/codemirror'
  'cs!compilers/icedcoffeescript/highlighter'
  'compilers/icedcoffeescript/compiler'
  'cs!source/TimeLine'
  'cs!source/RegexUtil'
], (jc_, jac_, CodeMirror, cmcs_, IcedCoffeeScript, TimeLine, RegexUtil) ->          
  sourceFragment = "try:"
  compiledJS = ''
  compiler = null
  compilerOptions = null
  sourceCompiled = false
  autoCompile = true
  lastHit = 0  

  AUTOSAVE_DELAY = 6000
  LAST_CODE = "lastEditedSourceCode"
  UNNAMED_CODE = "@unnamed"
  sourceChanged = false
  saveName = UNNAMED_CODE

  timeline = new TimeLine

  addMessage = (text) ->
    newMessage = $("<pre>" + text + "</pre>")
    $('#consoleSpace').prepend newMessage
    setMaxPreWidth newMessage

  eraseMessages = ->
    $('#consoleSpace').empty()

  log = (input...) ->  
  #return false for i in input when not (typeof i in ["string", "number", "array", "object"])
    input = (format i ? "Nothing" for i in input)
    message = input.join ", "
    #message = input
    if message.length > 0
      addMessage lastMessage = message
    return

  repeat = (string, num) ->
    result = ""
    for i in num
      result += string
    result

  format = (input) ->
    if input == undefined
      "undefined"
    else if input == null
      "null"
    else if Array.isArray input
      input = (format a for a in input)
      input = input.join ', '
      "[" + input + "]"
    else if typeof input == 'object'
      if $.isEmptyObject input
        '{}'
      else
        MAX_SINGLE_LINE = 50
        SEP_LEN = 4
        totalLen = 0
        maxKeyLen = 0
        for key, val of input
          if key?
            input[key] = val = format val
            totalLen += key.length + val.length + SEP_LEN
        maxKeyLen = Math.max(maxKeyLen, key.length)
        MAX_KEY_INDENT = 10
        maxKeyLen = Math.min(maxKeyLen, MAX_KEY_INDENT)
        if totalLen > MAX_SINGLE_LINE
          output = "\n"
          for key, val of input
            if key?
              output += key + ": " + (repeat " ", (maxKeyLen + 1 - key.length)) + val + "\n"
          output
        else
          "{" + ((key + ": " + val for key, val of input).join ", ") + "}"
    else if input == ''
      '""'
    else
      input


  showImportantMessage = (type, message) ->
    $("#errorSpace").attr("class", type);
    $("#errorSpace pre").text(message);
    $("#errorSpace").stop(true, true).fadeIn(200);
    

  showErrorMessage = (message) ->
    showImportantMessage "errorMessage", message

  showFileMessage = (message) ->
    showImportantMessage "fileMessage", message

  currentMessage = -> $("#errorSpace pre").text()

  hideError = ->
    $("#errorSpace").fadeOut(2000)

  dump = ->
    compileCode() unless sourceCompiled
    if compiledJS
      log compiledJS 
    else 
      showErrorMessage "Fix: '#{currentMessage()}' first"

  compileAndRun = ->
    source = $.trim cmdline.getValue()
    return if source.length == 0
    timeline.push source
    #hideError()
    try
      if pref = source.match /^(< |:)/
        source = source[pref[0].length..]
        loop
          match = ""

          # Sets match if given keywords match a command keyword
          sc = (kw...) -> match = source.match RegexUtil.singleCommand kw...

          # Sets match if given keyword matches a param-command keyword
          pc = (kw) -> match = source.match RegexUtil.paramCommand kw

          # Goes through all commands, trying to match command line input
          if sc "dump", "d" then dump()
          else if sc "erase", "e"  then eraseMessages()
          else if sc "link", "l"   then saveToAdress()
          else if sc "toggle", "t" then autoCompile = not autoCompile
          else if pc "save"        then switchCurrentCode RegexUtil.param match
          else if pc "load"        then loadFromClient RegexUtil.param match
          else if sc "close"       then exitCurrentCode()
          else if pc "delete"      then removeFromClient RegexUtil.param match
          else if sc "modes"       then displayModes()
          else if pc "mode"        then setMode RegexUtil.param match
          #else if match = source.match /^\s*(wipe\sall\ssaved)\b\s*/
            #wipeClient()
          else if sc "browse", "b" then displayClient()
          else if sc "help", "h"   then log helpDescription

          break unless match?
          source = source[match[0].length..]
          break if source.length == 0
      else
        command = compiler.compile source, getCompilerOptions()
        try        
          log execute compiledJS + command
        catch error
          showErrorMessage "Runtime: " + error
    catch error
      showErrorMessage "Command Line: " + error.message

  modes =
    CoffeeScript: 
      id: "coffeescript"  
      highlighter: "cs"
      options:
        bare: on
    IcedCoffeeScript: 
      id: "icedcoffeescript" 
      highlighter: "cs"
      options:
        bare: on 
    OmetaJS:
      id: "ometajs"
      compiler: "cs"
      options:
        beautify: on
      init: ->
        require ['compilers/ometa/lib/ometajs'], (ometajs) ->
          window.ometajs = ometajs
    Ometa:
      id: "ometa"
      compiler: "cs"

  modesList = ->
    output = ""
    for name of modes      
      output += "#{name}\n"
    output

  displayModes = ->
    log modesList()    

  setMode = (name) ->
    mode = modes[name]
    if mode?
      id = mode.id
      scriptPrefix = (fileType) -> if fileType == "cs" then "cs!" else ""
      require [
        # set to load via cs! if compiler is written in CoffeeScript
        "#{scriptPrefix mode.compiler}compilers/#{id}/compiler"
        "#{scriptPrefix mode.highlighter}compilers/#{id}/highlighter"
      ], (compilerClass, highlighter) ->
        compiler = compilerClass
        compilerOptions = mode.options
        editor.setOption "mode", id
        cmdline.setOption "mode", id
        mode.init?()
        log "#{name} compiler loaded"
        compileCode()
      , (error) ->
        log "#{name} loading failed"
    else
      log "Wrong mode name, choose from:\n\n" + modesList()

  getCompilerOptions = -> 
    $.extend {}, compilerOptions

  compileCode = ->
    startColor = "#151515" # "#303251"
    endColor = "#ccc"
    normalColor = "#050505" #"#202241"
    indicator = $('#compilationIndicator');
    indicateBy = (color) -> indicator.animate 'color': color,
      'complete': -> indicator.css 'color': color

    compileSource (-> indicateBy startColor), ->
      indicateBy endColor
      indicateBy normalColor

  # Set up the compilation function, to run when you stop typing.
  compileSource = (start, finish) ->  
    start()
    source = editor.getValue()
    compiledJS = ''
    try
      compiledJS = compiler.compile source, getCompilerOptions()
      hideError()
    catch error
      showErrorMessage "Compiler: " + error.message
    sourceCompiled = true
    finish()

    # Update permalink
    $('#repl_permalink').attr 'href', "##{sourceFragment}#{encodeURIComponent source}"


  execute = (code) ->
    console.log compiler.preExecute?(code) ? code
    eval compiler.preExecute?(code) ? code

  # Listen for changes and recompile.
  changeLer = (inst, e) ->
    sourceCompiled = false
    sourceChanged = true
    return unless autoCompile
    DELAY = 500
    lastHit = getTime()
    await setTimeout defer(), 2 * DELAY
    if getTime() - lastHit > DELAY
      compileCode() unless sourceCompiled

  getTime = -> new Date().getTime()

  BROWSE_COOKIE = "table"

  autosave = ->
    await setTimeout defer(), AUTOSAVE_DELAY
    if sourceChanged
      saveCurrent()
      sourceChanged = false
    autosave()
    return

  saveCurrent = ->
    value = editor.getValue()
    valueLines = (value.split "\n").length
    exists = false
    ammendClientTable saveName, "#{saveName},#{valueLines}"
    $.cookie saveName, value, expires: 365
    $.cookie LAST_CODE, saveName, expires: 365

  removeFromClient = (name) ->
    return unless name?
    $.cookie name, null, expires: 365
    ammendClientTable name
    showFileMessage "#{name} deleted"

  ammendClientTable = (exclude, addition = null) ->
    table = []
    oldTable = $.cookie BROWSE_COOKIE
    if oldTable?
      for pair in oldTable.split ";"
        [name, lines] = pair.split ","
        table.push pair unless name == exclude
    table.push addition if addition
    table = table.join ";"
    table = null if table.length == 0
    console.log "changed #{exclude} saving " + table
    $.cookie BROWSE_COOKIE, table, expires: 365

  loadFromClient = (name) ->
    name = $.cookie LAST_CODE unless name?
    return unless name?
    console.log "loading " + name + " is " + $.cookie name
    stored = $.cookie name
    if stored?
      saveName = name
      editor.setValue stored
      showFileMessage "#{saveName} loaded" if saveName != UNNAMED_CODE
    else
      showFileMessage "There is no #{saveName}" if saveName != UNNAMED_CODE

  exitCurrentCode = ->
    saveCurrent()
    saveName = UNNAMED_CODE
    editor.setValue ""
    saveCurrent()

  switchCurrentCode = (name) ->
    saveCurrent()
    saveName = name
    saveCurrent()
    showFileMessage "Working on #{saveName}"

  displayClient = ->
    table = $.cookie BROWSE_COOKIE
    unless table? and table.length > 0
      log null
      return
    output = ""
    for snippet in table.split ";"
      [name, lines] = snippet.split ","
      output += "#{name}, lines: #{lines}\n" unless name == UNNAMED_CODE
    log output

  CodeMirror.keyMap.commandLine =
    "Up": "doNothing"
    "Down": "doNothing"
    "PageUp": "doNothing"
    "PageDown": "doNothing"
    "Enter": "doNothing"
    fallthrough: "default"

  CodeMirror.commands.doNothing = (cm) -> true

  cmdLineKeyLer = (inst, e) ->
    if e.type == "keyup"
      shouldStop = true
      switch CodeMirror.keyNames[e.keyCode]
        when "Enter"
          compileAndRun()
          cmdline.setValue ""
        when "Up"
          timeline.temp cmdline.getValue() unless timeline.isInPast()
          cmdline.setValue timeline.goBack()
        when "Down"
          cmdline.setValue timeline.goForward() if timeline.isInPast()
        when "Esc"
          editor.focus()
        else
          shouldStop = false
      e.stop() if shouldStop
  

  resizeEditor = (e) ->
    $('#wrapcode .CodeMirror-scroll').css "max-height", ($(window).height() - 175) + "px"
    $('#rightColumn').css "max-height", ($(window).height() - 35) + "px"
    setMaxPreWidth $('#consoleSpace pre')

  setMaxPreWidth = ($pre) ->
    $pre.css "max-width", ($(window).width() * 0.5 - 95) + "px"  

    # Load the console with a string of CoffeeScript.
  loadConsole = (coffee) ->
    editor.setValue(editor.getValue() + coffee)
    compileCode()
    false


  saveToAdress = () ->
    source = editor.getValue()
    window.location = "##{sourceFragment}#{encodeURIComponent source}"

  helpDescription = """
  Issue commands by typing "< " or ":"
  followed by space separated commands:

  erase / e     - Clear all results
  dump / d      - Dump generated javascript
  toggle / t    - Toggle autocompilation
  link / l      - Create a link with current source code
  mode &lt;name>   - Switch to a different compiler
  modes         - Show all available modes
  save &lt;name>   - Save current code locally under name
  load &lt;name>   - Load code from local storage under name
  delete &lt;name> - Remove code from local storage
  browse / b    - Show content of local storage
  help / h      - Show this help

  Name with arbitrary characters (spaces) must be closed by \\
  save Long file name.txt\\
  """
  
  
  # Initialize CodeMirror
  # ---------------------

  # References to active line
  hlLine = null

  editor = CodeMirror.fromTextArea $("#code").get(0),
    tabSize: 2
    indentUnit: 2
    lineNumbers: true
    extraKeys: "Tab": "indentMore", "Shift-Tab": "indentLess"
    onChange: (inst, e) -> changeLer inst, e
    onCursorActivity: ->
      editor.setLineClass hlLine, null, null
      hlLine = editor.setLineClass editor.getCursor().line, null, "activeline"

  hlLine = editor.setLineClass 1, null, "activeline" # doesn't work as expected

  cmdline = CodeMirror.fromTextArea $("#code2").get(0),
    tabSize: 2
    indentUnit: 2
    keyMap: "commandLine"
    onKeyEvent: (inst, e) -> cmdLineKeyLer inst, e

  # Editor Functionality
  # ---------------------

  $(editor.getInputField()).keyup (e) ->
    switch CodeMirror.keyNames[e.keyCode]
      when "Esc"
        cmdline.focus()


  $('#wrapcmd .CodeMirror').mouseenter (e) ->
    cmdline.focus()

  $('#wrapcode .CodeMirror').mouseenter (e) ->
    editor.focus()

  # Editor Sizing
  # ---------------------

  resizeEditor()
  $(window).resize resizeEditor
    #wipe all saved - Wipes local storage

  # Start Editing
  # ---------------------

  # Set a default compiler
  compiler = IcedCoffeeScript
  compilerOptions = bare: on

  # If source code is included in location.hash, display it.
  hash = decodeURIComponent window.location.hash.replace(/^#/, '')
  if hash.indexOf(sourceFragment) == 0
    src = hash.substr sourceFragment.length
    loadConsole src
  else
    loadFromClient()

  autosave()
  compileCode()