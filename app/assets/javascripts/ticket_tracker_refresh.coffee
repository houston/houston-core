$ ->
  $button = $('#sync_tickets_button')
  $button.find('[data-toggle="tooltip"]').tooltip()
  $button.click (e)->
    e.preventDefault()
    return if $button.hasClass('working') or $button.hasClass('done')
    
    $button.addClass('working')
    
    $("<div class=\"alert alert-info\">Your project is being synced with #{$button.attr('data-tracker')}</div>").prependTo($('#body')).alert()
    
    xhr = $.post $button.attr('href')
    xhr.complete => $button.removeClass('working')
    xhr.success =>
      $('.alert').remove()
      $("<div class=\"alert alert-success\">Your project is up-to-date! <a href=\"#{window.location}\">Refresh</a> to see the latest tickets.</div>").prependTo($('#body')).alert()
      $button.addClass('done')
    
    xhr.error =>
      $('.alert').remove()
      $("<div class=\"alert alert-error\">Your project could not be synced with #{$button.attr('data-tracker')}</div>").prependTo($('#body')).alert()
