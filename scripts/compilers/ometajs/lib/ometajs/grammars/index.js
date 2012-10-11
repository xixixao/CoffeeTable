define([
  './ometajs',
], function (ometajs) {

var grammars = {}

grammars.AbstractGrammar = ometajs.core.AbstractGrammar;

// Lazy getters for BSJS stuff
var bsjs = undefined;

function lazyDescriptor(property) {
  return {
    enumerable: true,
    get: function get() {
      if (bsjs === undefined) 
        require(['compilers/ometa/lib/ometajs/grammars/bsjs'], function () {

      });

      return bsjs[property];
    }
  };
}

Object.defineProperties(grammars, {
  BSJSParser: lazyDescriptor('BSJSParser'),
  BSJSIdentity: lazyDescriptor('BSJSIdentity'),
  BSJSTranslator: lazyDescriptor('BSJSTranslator')
});

return grammars;

});
