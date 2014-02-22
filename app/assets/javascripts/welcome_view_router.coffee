class @WelcomeViewRouter extends Backbone.Router
  
  routes:
    '':                   'goToTimeline'
    'timeline':           'showTimeline'
    'to-do':              'showToDo'
  
  
  initialize: (options)->
    @parent = options.parent
    @$triptych = $('#triptych')
    @$triptych.bind 'transitionend webkitTransitionEnd oTransitionEnd MSTransitionEnd', =>
      @collapseOffscreenPages()
  
  
  goToTimeline: ->
    window.location.hash = 'timeline'
  
  showTimeline: ->
    @slideTo 0
    @show 'timeline'
    
  showToDo: ->
    @slideTo 1
    @show 'todo'
  
  show: (id) ->
    @activateTab "#nav_#{id}"
  
  slideTo: (n)->
    $('#triptych > div').removeClass('collapsed')
    $('#triptych').attr 'data-page', n
  
  activateTab: (id)->
    $(".active:not(#{id})").removeClass('active')
    $(id).addClass('active')

  collapseOffscreenPages: ->
    $("#triptych > div:not(:eq(#{@$triptych.attr('data-page')}))").addClass('collapsed')
