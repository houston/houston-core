$ ->
  $button = $('#sync_tickets_button')
  $button.find('[data-toggle="tooltip"]').tooltip()
  $button.click (e)->
    e.preventDefault()
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
