class @WelcomeView extends Backbone.View
  
  initialize: ->
    @router = new WelcomeViewRouter(parent: @)
    Backbone.history.start()
    
    window.setTimeout =>
      @router.collapseOffscreenPages()
      $('#triptych').addClass 'slider'
    , 0
