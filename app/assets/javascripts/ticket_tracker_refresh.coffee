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
  
  
  showKeyboardShortcuts = ->
    new KeyboardShortcutsModal().show()
  
  
  $button = $('#sync_tickets_button')
  $button.find('[data-toggle="tooltip"]').tooltip()
  
  Mousetrap.bind 'R t', -> $button.click()
  $button.click (e)->
    e.preventDefault()
    refreshTickets()
  
  
  Mousetrap.bind 'n t', -> $('#new_ticket_button').click()
  $('#new_ticket_button').click (e)->
    e.preventDefault()
    App.showNewTicket()
  
  
  Mousetrap.bind 'g p', -> window.location = '/projects'
  Mousetrap.bind 'g q', -> window.location = '/pull_requests'
  Mousetrap.bind 'g i', -> window.location = '/itsm/issues'
  Mousetrap.bind 'g t r', -> window.location = '/testing_report'
  Mousetrap.bind 'g n t', -> window.location = '/tickets/new'
  Mousetrap.bind 'g u', -> window.location = '/users'
  
  
  Mousetrap.bind '?', ->  $('#keyboard_shortcuts_button').click()
  $('#keyboard_shortcuts_button').click (e)->
    e.preventDefault()
    showKeyboardShortcuts()
