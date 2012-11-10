require [
  'lib/jquery/jquery.cookie'
  'lib/jquery/jquery.total-storage'
  'lib/jquery/jquery.animate-colors'
  'lib/jquery/jquery.select-text'
  'cs!lib/jquery/jquery.repeat'
  'lib/cm/codemirror'
  'cs!compilers/icedcoffeescript/highlighter'
  'compilers/icedcoffeescript/compiler'
  'cs!source/UniqueTimeLine'
  'cs!source/RegexUtil'
  'source/jsDump'
  'compilers/ometaws/lib/lib/cs/compiler'
], (jc_, jts, jac_, jst_, jr_, CodeMirror, cmcs_, IcedCoffeeScript, TimeLine, RegexUtil, jsDump, csc) ->
  sourceFragment = "try:"
  compiledJS = ''
  compiler = null
  compilerOptions = null
  sourceCompiled = false
  autoCompile = true
  lastHit = 0
  lastErrorType = ""
  currentMode = ""

  AUTOSAVE_DELAY = 6000
  LAST_CODE = "lastEditedSourceCodeCOOKIE"
  UNNAMED_CODE = "@unnamed"
  TIMELINE_COOKIE = "timelineCOOKIE"
  sourceChanged = false
  saveName = UNNAMED_CODE
  cookieFilePrefix = "TeaTableFile_";

  timeline = new TimeLine

  addMessage = (text) ->
    newMessage = $("<pre>" + text + "</pre>")
    $('#consoleSpace').prepend newMessage
    setMaxPreWidth newMessage

  eraseMessages = ->
    $('#consoleSpace').empty()

  getMessage = (n) ->
    $('#consoleSpace pre').eq n

  log = (input...) ->
  #return false for i in input when not (typeof i in ["string", "number", "array", "object"])
    input = (jsDump.parse i ? "Nothing" for i in input)
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

  showImportantMessage = (type, message) ->
    $("#errorSpace").attr("class", type);
    $("#errorSpace pre").text(message);
    $("#errorSpace").stop(true, true).fadeIn(200);

  showErrorMessage = (type, message) ->
    lastErrorType = type
    showImportantMessage "errorMessage", message

  showFileMessage = (message) ->
    showImportantMessage "fileMessage", message

  currentMessage = -> $("#errorSpace pre").text()

  hideError = (types...) ->
    if lastErrorType in types
      $("#errorSpace").fadeOut(700)

  dump = ->
    compileCode() unless sourceCompiled
    if compiledJS
      log compiledJS
    else
      showErrorMessage "compiler", "Fix: '#{currentMessage()}' first"

  compileAndRun = ->
    source = $.trim cmdline.getValue()
    return if source.length == 0
    timeline.push source
    hideError "command", "runtime"
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
          else if sc "copy", "c"   then selectLastOutput()
          else if sc "link", "l"   then saveToAdress()
          else if sc "toggle", "t" then toggleAutoCompilation()
          else if pc "save"        then switchCurrentCode RegexUtil.param match
          else if pc "load"        then loadFromClient RegexUtil.param match
          else if sc "close"       then exitCurrentCode()
          else if pc "delete"      then removeFromClient RegexUtil.param match
          else if sc "modes", "m"  then displayModes()
          else if pc "mode"        then setMode RegexUtil.param match
          #else if match = source.match /^\s*(wipe\sall\ssaved)\b\s*/
            #wipeClient()
          else if sc "browse", "b" then displayClient()
          else if sc "help", "h"   then log helpDescription

          break unless match?
          source = source[match[0].length..]
          break if source.length == 0
        saveTimeline()
        outputScrollTop()
      else
        command = compiler.compile source, getCompilerOptions()
        try
          log execute compiledJS + command
          saveTimeline()
          outputScrollTop()
        catch error
          showErrorMessage "runtime", "Runtime: " + error
    catch error
      console.log error
      showErrorMessage "command", "Command Line: " + error.message

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
    OmetaWS:
      id: "ometaws"
      compiler: "cs"

  modesList = ->
    output = ""
    for name of modes
      output += "#{name}\n"
    output

  displayModes = ->
    log modesList()

  setNewMode = (name, callback) ->
    if name isnt currentMode
      setMode name, callback
    else
      callback?()

  setMode = (name, callback) ->
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
        currentMode = name
        compileCode()
        callback?()
      , (error) ->
        log "#{name} loading failed"
    else
      log "Wrong mode name, choose from:\n\n" + modesList()

  toggleAutoCompilation = ->
    autoCompile = not autoCompile
    log "Autocompilation switched " + if autoCompile then "on" else "off"

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
    saveCurrent()
    try
      compiledJS = compiler.compile source, getCompilerOptions()
      hideError "compiler", "runtime"
    catch error
      showErrorMessage "compiler", "Compiler: " + (error.message ? error)
    sourceCompiled = true
    finish()

    # Update permalink
    $('#repl_permalink').attr 'href', "##{sourceFragment}#{encodeURIComponent source}"


  execute = (code) ->
    #console.log compiler.preExecute?(code) ? code
    eval compiler.preExecute?(code) ? code

  # Listen for changes and recompile.
  changeLer = (inst, e) ->
    sourceCompiled = false
    sourceChanged = true
    return unless autoCompile
    DELAY = 700
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


  fileCookie = (name, value) ->
    $.totalStorage cookieFilePrefix + name, value

  saveCurrent = ->
    source = editor.getValue()
    value = source: source, mode: currentMode
    valueLines = (source.split "\n").length
    exists = false
    ammendClientTable saveName, "#{saveName},#{valueLines}"
    fileCookie saveName, value
    $.totalStorage LAST_CODE, saveName

  saveTimeline = ->
    $.totalStorage TIMELINE_COOKIE, timeline.newest(200)

  loadTimeline = ->
    timeline.from ($.totalStorage TIMELINE_COOKIE) ? []

  removeFromClient = (name) ->
    return unless name?
    fileCookie saveName, null
    ammendClientTable name
    showFileMessage "#{name} deleted"

  ammendClientTable = (exclude, addition = null) ->
    table = []
    oldTable = $.totalStorage BROWSE_COOKIE
    if oldTable?
      for pair in oldTable.split ";"
        [name, lines] = pair.split ","
        table.push pair unless name == exclude
    table.push addition if addition
    table = table.join ";"
    table = null if table.length == 0
    #console.log "changed #{exclude} saving " + table
    $.totalStorage BROWSE_COOKIE, table

  loadFromClient = (name) ->
    name = $.totalStorage LAST_CODE unless name?
    return unless name?
    #console.log "loading " + name + " is " + $.totalStorage name
    stored = fileCookie name
    if stored?
      saveName = name
      {source, mode} = stored
      editor.setValue source
      setNewMode mode, ->
        showFileMessage "#{saveName} loaded" if saveName != UNNAMED_CODE
    else
      showFileMessage "There is no #{name}" if name != UNNAMED_CODE

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
    table = $.totalStorage BROWSE_COOKIE
    output = ""
    if table? and table.length > 0
      for snippet in table.split ";"
        [name, lines] = snippet.split ","
        output += "#{name}, lines: #{lines}\n" unless name == UNNAMED_CODE
    if output == ""
      log "No files saved"
    else
      log output

  CodeMirror.keyMap.commandLine =
    "Up": "doNothing"
    "Down": "doNothing"
    "PageUp": "doNothing"
    "PageDown": "doNothing"
    "Enter": "doNothing"
    fallthrough: "default"

  CodeMirror.commands.doNothing = (cm) -> true

  outputScrollTop = ->
    $('#rightColumn').animate {scrollTop: 0}, $('#rightColumn').scrollTop() / 10

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
    winSize = w: $(window).width(), h: $(window).height()
    column = winSize.w / 2
    $('.CodeMirror-border').css "width", (column - 10) + "px"
    $('#wrapcode .CodeMirror-scroll').css "max-height", (winSize.h - 175) + "px"
    $('#rightColumn').css "left", (column) + "px"
    $('#rightColumn').css "width", (column - 35) + "px"
    $('#rightColumn').css "max-height", (winSize.h - 35) + "px"
    setMaxPreWidth $('#consoleSpace pre')

  selectLastOutput = ->
    (getMessage 0).selectText()

  setMaxPreWidth = ($pre) ->
    $pre.css "max-width", ($(window).width() * 0.5 - 95) + "px"

    # Load the editor with a string of CoffeeScript.
  loadWith = (coffee) ->
    editor.setValue(editor.getValue() + coffee)

  saveToAdress = () ->
    source = editor.getValue()
    window.location = "##{sourceFragment}#{encodeURIComponent source}"

  helpDescription = """
  Issue commands by typing "< " or ":"
  followed by space separated commands:

  erase / e     - Clear all results
  dump / d      - Dump generated javascript
  copy / c      - Select last output (right-click to copy)
  toggle / t    - Toggle autocompilation
  link / l      - Create a link with current source code
  mode &lt;name>   - Switch to a different compiler
  modes / m     - Show all available modes
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

  # Autosave
  # --------
  # Apart from compilation also on closing window
  $(window).unload ->
    saveCurrent()


  # Start Editing
  # ---------------------

  # Set a default compiler
  compiler = IcedCoffeeScript
  compilerOptions = bare: on
  currentMode = "IcedCoffeeScript"

  # If source code is included in location.hash, display it.
  hash = decodeURIComponent window.location.hash.replace(/^#/, '')
  if hash.indexOf(sourceFragment) == 0
    src = hash.substr sourceFragment.length
    loadWith src
  else
    loadFromClient()

  loadTimeline()

  if timeline.size() < 10
    cmdline.setValue ":help"

  #autosave()
  #compileCode()