define [
  'compilers/ometa/lib/ometajs'
], (ometajs) ->    
  # options are ignored
  compile: (text, options) ->
    ast      = ometajs.parser.create(text).execute()
    compiler = ometajs.compiler.create ast, options

    compiler.execute()


###
define [
  'compilers/ometa/source/bs-ometa-js-compiler'
], (BSOMetaJSCompiler) ->  
  {BSOmetaJSParser, BSOmetaJSTranslator} = BSJSCompiler
  class OmetaJS
    # options are ignored
    compile: (text, options = {}) ->      
      parsed = BSOMetaJSParser.matchAll s, "topLevel", undefined, (m, i) ->
        throw objectThatDelegatesTo fail, errorPos: i
      
      compiled = BSOMetaJSTranslator.match parsed, "trans", undefined, (m, i) -> 
        throw new Eror "Translation error - please tell Alex about this!\nm: #{m}\ni: #{i}"
      ###