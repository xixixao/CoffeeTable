//require.config({
//});
require({
  paths: {
    cs:              'lib/requirejs/cs',
    'coffee-script': 'lib/cs/coffee-script-iced',
    ometajs:         'compilers/ometa/lib/ometajs'
  }
}, ['cs!source/editor']);