$ ->
  
  refreshTickets = ->
    return if $button.hasClass('working') or $button.hasClass('done')
    
    $button.addClass('working')
    
    $("<div class=\"alert alert-info\">Your project is being synced with #{$button.attr('data-tracker')}</div>").appendAsAlert()
    
    xhr = $.post $button.attr('href')
    xhr.complete => $button.removeClass('working')
    xhr.success =>
      $("<div class=\"alert alert-success\">Your project is up-to-date! <a href=\"#{window.location}\">Refresh</a> to see the latest tickets.</div>").appendAsAlert()
      $button.addClass('done')
    
    xhr.error =>
      $("<div class=\"alert alert-error\">Your project could not be synced with #{$button.attr('data-tracker')}</div>").appendAsAlert()
  
  
  showNewTicket = ->
    $banner = $('.project-banner')
    slug = $banner.attr('data-project-slug')
    color = $banner.attr('data-project-color')
    if slug and $('#new_ticket_modal').length is 0
      new NewTicketModal(slug: slug, color: color).show()
  
  
  showKeyboardShortcuts = ->
    new KeyboardShortcutsModal().show()
  
  
  $button = $('#sync_tickets_button')
  $button.find('[data-toggle="tooltip"]').tooltip()
  $button.click (e)->
    e.preventDefault()
    refreshTickets()
  Mousetrap.bind('R t', refreshTickets)
  
  
  $('#new_ticket_button').click (e)->
    e.preventDefault()
    showNewTicket()
  Mousetrap.bind('n t', showNewTicket)
  
  
  $('#keyboard_shortcuts_button').click (e)->
    e.preventDefault()
    showKeyboardShortcuts()
  Mousetrap.bind('?', showKeyboardShortcuts)
