define ->
  class TimeLine
    constructor: ->
      @head = 0
      @now = 0
      @elems = []
      @temporary = null

    push: (e) ->
      @elems[@head] = e
      @head++
      @goNewest()

    temp: (e) ->
      @temporary = e
      @goNewest()

    goBack: ->
      @now-- if @now > 0
      @curr()

    goForward: ->
      res = @curr()
      @now++ if @now < @head
      @curr()

    goOldest: ->
      @now = 0
      @curr()

    goNewest: ->
      @now = @head
      @curr()

    isInPast: ->
      @now < @head

    curr: ->
      if @now == @head then @temporary
      else @elems[@now]