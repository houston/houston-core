window.App.NewReleaseForm =
  
  init: (options)->
    $nestedEditor = $('.changes-nested-editor')
    $nestedEditor.find('.add-link, .delete-link').attr('tabindex', '-1')
    $nestedEditor.delegate '.change-description input', 'keypress', (e)->
      if e.keyCode == 13
        e.preventDefault()
        e.stopImmediatePropagation()
        FT.addNestedRow(FT.getNestedRowFromEvent(e));
    $nestedEditor.delegate '.change-description input', 'keyup', (e)->
      if e.keyCode == 8 and $(this).val() == ''
        e.preventDefault()
        e.stopImmediatePropagation()
        FT.deleteNestedRow(FT.getNestedRowFromEvent(e));      
      if e.keyCode == 38
        $(this).closest('.nested-row').prev().find('input').select()
      if e.keyCode == 40
        $(this).closest('.nested-row').next().find('input').select()
    
    ticketSummaries = []
    ticketBySummary = {}
    for ticket in options.tickets
      summary = "[##{ticket.number}] #{ticket.summary}"
      ticketSummaries.push summary
      ticketBySummary[summary] = ticket
    
    addTicket = (ticket)->
      return if $("#ticket_#{ticket.id}").length > 0
      html = """
      <li id="ticket_#{ticket.id}">
        <input type="hidden" name="release[ticket_ids][]" value="#{ticket.id}" />
        <a href="#{ticket.ticketUrl}" target="_blank">[##{ticket.number}] #{App.formatTicketSummary(ticket.summary)}</a>
        <a class="delete-link delete-nested-link" href="#" title="Delete" tabindex="-1">Delete</a>
      </li>
      """
      $('#new_ticket_li').before(html)
    
    $('#release_tickets').delegate '.delete-link', 'click', (e)->
      e.preventDefault()
      $(@).closest('li').remove()
    
    selectedTicket = null
    $('#new_ticket_field')
      .typeahead
        source: ticketSummaries
        updater: (item)->
          selectedTicket = ticketBySummary[item]
          item
      .keydown (e)->
        if e.keyCode is 13
          e.preventDefault()
          addTicket(selectedTicket) if selectedTicket
          $('#new_ticket_field').val('')
