window.FnordMetric ||= {}

class window.FnordMetric.Connection
  
  constructor: (options) ->
    @namespace = options.namespace
    @observer = new Observer()
    @host = options.host || document.location.host
    @connect()
  
  observe: (event, callback)->
    @observer.observe(event, callback)
  
  connect: ->
    @socket = new WebSocket("ws://#{@host}/stream")
    @socket.onmessage = _.bind(@socketMessage, @)
    @socket.onclose = _.bind(@socketClose, @)
    @socket.onopen = _.bind(@socketOpen, @)
  
  publish: (obj)->
    obj.namespace ||= @namespace
    @socket.send(JSON.stringify(obj))
  
  socketMessage: (raw)->
    evt = JSON.parse(raw.data)
    
    if evt.class == 'widget_response'
      @observer.fire("#{evt.widget_key}.#{evt.cmd}", evt)
      @observer.fire("#{evt.widget_key}.*", evt)
    else
      @observer.fire(evt.type, evt)
    @observer.fire('*', evt)
  
  socketOpen: ->
    window.console.log('connected...')
    $('.flash-message-over').fadeOut -> $(this).remove()
  
  socketClose: ->
    window.console.log('socket closed')
    
    if $('.flash-message-over').length == 0
      $('body')
        .append($('<div class="flash-message-over">')
          .append($('<div class="inner">')
            .append('<h1>Oopsiedaisy, lost the connection...</h1>')
            .append('<h2>Reconnecting to server...</h2>')
            .append('<div class="loader_white">')))
      
      window.setTimeout (-> $('.flash-message-over').addClass('visible')), 20
    
    window.setTimeout(_.bind(@connect, @), 1000)
