# Require.js config
require
  urlArgs: "b=#{(new Date()).getTime()}"
  paths:
    hyper: 'vendor/hyper/hyper'
    React: 'vendor/react/react'
    jqueryLibs: 'vendor/jquery'
    jquery: 'vendor/jquery/jquery'
    ejquery: 'app/jquery.extended'
  shim:
    'vendor/jquery/jquery.cookie': ['jquery']
    'vendor/jquery/jquery.total-storage': ['jquery']
    'vendor/jquery/jquery.animate-colors': ['jquery']
    'vendor/jquery/jquery.select-text': ['jquery']
    'vendor/jquery/jquery.repeat': ['jquery']
    'vendor/jquery/jquery-ui-draggable': ['jquery']
  , ['app/editor']