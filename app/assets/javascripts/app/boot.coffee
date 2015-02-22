$ ->
  
  $('a[rel=popover]').popover()
  $('.tooltip').tooltip()
  $('a[rel=tooltip]').tooltip()
  
  $('[rel="tooltip"]').each ->
    $el = $(@)
    placement = $el.attr('data-tooltip-placement') || 'bottom'
    $el.tooltip
      placement: placement
  
  $('.project-banner').affix(offset: {top: 70})
  
  $('body').on 'click', '[rel="ticket"]', (e)->
    $link = $(@)
    number = +$link.attr('data-number')
    project = $link.attr('data-project')
    $context = $link.closest('#tickets')
    e.preventDefault() if App.showTicket(number, project, $context: $context)
