define [
 'cs!./lib/src/ometajs'
 'cs!./lib/workspace/ErrorHandler'
], (OMetaJS, ErrorHandler) ->    
  # options are ignored
  compile: (text, options) ->

    ast = OMetaJS.BSOMetaJSParser.matchAll text, 
      "topLevel", undefined, (m, i) ->
          handled = ErrorHandler.handle m, i
          throw new Error "Parser error at line " + (handled.lineNumber + 1) + "\n" + 
            ErrorHandler.bottomErrorArrow handled
    code = OMetaJS.BSOMetaJSTranslator.match ast, 
      "trans", undefined, (m, i) ->
        handled = ErrorHandler.handle m, i
        throw new Error "Translation error at line" + (handled.lineNumber + 1) + "\n" + 
          ErrorHandler.bottomErrorArrow handled
    
  preExecute: (code) ->
    window.OMetaJS = OMetaJS
    
    window.ometaError = (m, i) ->
      handled = ErrorHandler.handle m, i
      "Error at line " + (handled.lineNumber + 1) + "\n" +
        ErrorHandler.bottomErrorArrow handled

    "ometaError = window.ometaError;" +

    "OmetaJS = window.OMetaJS;" +
    "OMeta = OMetaJS.OMeta; " +
    "OMLib = OMetaJS.OMLib; " +
    "BSOMetaJSParser = OMetaJS.BSOMetaJSParser;" +
    "BSOmetaJSTranslator = OMetaJS.BSOmetaJSTranslator;" +
    "escapeChar = OMLib.escapeChar;" +
    "unescape = OMLib.unescape;" +
    "propertyNames = OMLib.propertyNames;" +
    "Set = OMLib.Set;" +
    "programString = OMLib.programString;" +
    "subclass = OMLib.subclass;" +
    "StringBuffer = OMLib.StringBuffer;" + code

    