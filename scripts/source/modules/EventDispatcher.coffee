define ->

  # Objects inheriting from this class behave like DOM objects with events,
  # they can be bound to and they can trigger events.
  #
  # Events must be declared in @events object
  class EventDispatcher
    trigger: (type, params...) ->
      for h in @eventHandles[type]
        h params...
      this

    propagate: (eventDispatcher, type) ->
      eventDispatcher.bind type, (args...) ->
        @trigger type, args...

    bind: (type, handle) ->
      unless @events[type]
        throw new Error("Event '#{type}' not defined for #{@constructor.name}");      
      @eventHandles ?= {}
      (@eventHandles[type] ?= []).push handle
      this

    unbind: (type, handle) ->
      hs = @eventHandles?[type]      
      lastOccurence = hs?.lastIndexOf handle
      if lastOccurence >= 0
        hs.splice lastOccurence 1
      this

###

class StateMachine
  trans: (state) ->
    @currentState = state
    
  dispatch: (event) ->
    @currentState event

###