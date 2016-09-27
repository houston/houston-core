$ ->

  refreshTickets = ->
    return if $button.hasClass('working') or $button.hasClass('done')

    $button.addClass('working')

    alertify.log "Your project is being synced with #{$button.attr('data-tracker')}"

    xhr = $.post $button.attr('href')
    xhr.complete => $button.removeClass('working')
    xhr.success =>
      alertify.success "Your project is up-to-date! <a href=\"#{window.location}\">Refresh</a> to see the latest tickets."
      $button.addClass('done')

    xhr.error =>
      alertify.error "Your project could not be synced with #{$button.attr('data-tracker')}"

  $button = $('#sync_tickets_button')
  $button.find('[data-toggle="tooltip"]').tooltip()
  $button.click (e)->
    e.preventDefault()
    refreshTickets()
