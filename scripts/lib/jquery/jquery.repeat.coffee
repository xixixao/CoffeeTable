do ($ = jQuery) ->
  $.repeat = (num, what) ->
    Array(num + 1).join what

  $.join = (array) ->
    array.join ''