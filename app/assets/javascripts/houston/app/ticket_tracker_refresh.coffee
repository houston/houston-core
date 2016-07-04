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


  Mousetrap.bind 'G', (e)->
    e.preventDefault()

    renderItem = (item)-> HandlebarsTemplates["omnibar/#{item.type}"](item)
    renderItems = (items)-> _.reduce items, ((html, item)-> html + renderItem(item)), ''

    $modal = $(HandlebarsTemplates['omnibar/modal']()).modal()
    $modal.on 'hidden', => $modal.remove()
    $('#omnibar').focus().putCursorAtEnd().typeahead
      minLength: 2
      source: (query, process)->
        $.get '/omnibar', query: query, process
        false # don't render anything now, wait for $.get to call process
      updater: (url)->
        $modal.remove() # remove the modal but not the backdrop
        window.location.href = url
      matcher: (item)-> true # they all match (the server did the matching)
      sorter: (items)-> items # apply no sorting (return them in the order given)
    $('#omnibar').data('typeahead').render = (items)->
      @$menu.html(renderItems(items))
      @$menu.find('li:first').addClass('active')
      @
    $('#omnibar').on 'keyup', (e)-> $modal.modal('hide') if e.keyCode is 27

  Mousetrap.bind 'g p', -> window.location = '/projects'
  Mousetrap.bind 'g n t', -> window.location = '/tickets/new'
  Mousetrap.bind 'g u', -> window.location = '/users'


  Mousetrap.bind '?', ->  $('#keyboard_shortcuts_button').click()
  $('#keyboard_shortcuts_button').click (e)->
    e.preventDefault()
    showKeyboardShortcuts()
