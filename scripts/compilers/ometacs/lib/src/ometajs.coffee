define [
 'cs!../src/ometa-base',
 'cs!../src/lib',
 '../bin/bs-dentparser',
 '../bin/bs-js-compiler',
 '../bin/bs-ometa-compiler',
 '../bin/bs-ometa-optimizer',
 '../bin/bs-ometa-js-compiler',
 '../lib/cs/compiler'
 ], (OMeta, OMLib, BSDentParser, BSJCCompiler, BSOmetaCompiler, BSOmetaOptimizer, BSOmetaJSCompiler, BSCoffeeScriptCompiler) ->
  OMeta: OMeta
  OMLib: OMLib
  BSOMetaJSParser: BSOmetaJSCompiler.BSOMetaJSParser
  BSOMetaJSTranslator: BSOmetaJSCompiler.BSOMetaJSTranslator
  BSCoffeeScriptCompiler: BSCoffeeScriptCompiler