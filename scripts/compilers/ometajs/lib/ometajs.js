//
// OmetaJS
//

define([
  './ometajs/utils',
  './ometajs/lexer',
  './ometajs/compiler/ast',
  './ometajs/compiler/ir',
  './ometajs/compiler/core',
  './ometajs/parser',
  './ometajs/core/parser',
  './ometajs/core/grammar',
  //'./ometajs/legacy',
  './ometajs/grammars/bsjs'//,
  //'./ometajs/api',
  //'./ometajs/cli'  
], function (
  Utils, Lexer, 
  CompilerAST, CompilerIR, CompilerCore,
  Parser, 
  CoreParser, CoreGrammar,
  //Legacy, 
  Grammars//,
  //API, CLI
){

var ometajs = {};

// Export utils
ometajs.utils = Utils;

// Export lexer
ometajs.lexer = Lexer;

// Export compiler
ometajs.compiler = {};
ometajs.compiler.ast = CompilerAST;
ometajs.compiler.ir = CompilerIR(ometajs);
ometajs.compiler.create = CompilerCore(ometajs).create;

// Export parser
ometajs.parser = Parser(ometajs);

// Compiler routines
ometajs.core = {};
ometajs.core.AbstractParser = CoreParser;
ometajs.core.AbstractGrammar = CoreGrammar(ometajs);

/*
// Export legacy methods
var firstTime = false;
Object.defineProperty(ometajs, 'globals', {
  get: function () {
    if (!firstTime) {
      firstTime = true;
      console.error('!!!\n' +
                    '!!! Warning: you\'re using grammar compiled with ' +
                    'previous version of ometajs. Please recompile it with ' +
                    'the newest one\n' +
                    '!!!\n');
      ometajs.utils.extend(ometajs, require('./ometajs/legacy'));
    }
    return require('./ometajs/legacy');
  }
});
*/

// Export grammars
ometajs.grammars = {};
ometajs.grammars.AbstractGrammar = ometajs.core.AbstractGrammar;
ometajs.grammars = Grammars(ometajs);

// Export API
//ometajs.compile = API.compile;

// Export CLI
//ometajs.cli = CLI;

return ometajs;

});