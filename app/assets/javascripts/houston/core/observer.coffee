class EventChannelPromise

  constructor: ->
    @_onConnected = []
    @_onDisconnected = []
    @_onReceived = []


  # Client code can register callbacks lazily

  connected: (callback) ->
    @_onConnected.push callback
    @

  disconnected: (callback) ->
    @_onDisconnected.push callback
    @

  received: (callback) ->
    @_onReceived.push callback
    @


  # Should only be invoked below, by EventChannelObserver

  didConnect: ->
    for callback in @_onConnected
      callback()

  didDisconnect: ->
    for callback in @_onDisconnected
      callback()

  didReceive: (data) ->
    for callback in @_onReceived
      callback(data)



class EventChannelObserver

  constructor: ->
    @_subscriptions = {}

  on: (event, callback) ->
    promise = @_subscriptions[event]

    # We'll only subscribe to the event once, but
    # we can attach more callbacks to it later.
    unless promise
      promise = @_subscriptions[event] = new EventChannelPromise()

      # Wait a second so that an immediately-registered "connected"
      # callback will be invoked when the connection is established.
      window.setTimeout ->
        Houston.cable.subscriptions.create
          channel: "EventsChannel"
          event: event
        ,
          connected: -> promise.didConnect()
          disconnected: -> promise.didDisconnect()
          received: (data) -> promise.didReceive(data)

    # If a callback was passed, tie it to the `received` event
    promise.received(callback) if callback
    promise


Houston.observer = new EventChannelObserver()
