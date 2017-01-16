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

  isMobile = $('html').hasClass('mobile')

  if isMobile
    slideout = new Slideout
      panel: document.getElementById('body')
      menu: document.getElementById('slideout_menu')
      padding: 172
      tolerance: 70
