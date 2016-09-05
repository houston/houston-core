class @EditTicketView extends Backbone.View

  initialize: (options)->
    @options = options
    @ticket = @options.ticket

  render: ->
    @$el.find('.editable').pseudoHover()
    @$summary = @$el.find('#ticket_summary')
    @$description = @$el.find('#ticket_description')
    $textarea = @$description.find('textarea')

    $(window).resize =>
      $textarea.css height: @$description.parent().height() - (61 + 31)
    $textarea.css height: @$description.parent().height() - (61 + 31)

    $('.uploader').supportImages()

    @$el.find('.ticket-state').pseudoHover().click (e)=>
      action = if $(e.target).hasClass('open') then 'close' else 'reopen'
      @ticket[action]()
        .success (attributes)->
          $(e.target)
            .removeClass('hover')
            .toggleClass('open', !attributes.closedAt)
            .toggleClass('closed', !!attributes.closedAt)

    @$summary.find('.show').click (e)=>
      $editable = $(e.target).closest('.editable')
      $editable.addClass('in-edit')
      $editable.find('input').val(@ticket.get 'summary').focus().select()
      $editable.find('input').blur ->
        $input = $(e.target)
        $editable = $input.closest('.editable')
        $editable.removeClass('in-edit')

    @$description.find('.show').click (e)=>
      $editable = $(e.target).closest('.editable')
      $editable.addClass('in-edit')
      $editable.find('textarea').val(@ticket.get 'description').focus().select()

    @$summary.find('input').keydown (e)=>
      if e.keyCode is 27
        $input = $(e.target)
        $editable = $input.closest('.editable')
        $editable.removeClass('in-edit')
      if e.keyCode is 13
        $input = $(e.target)
        @ticket.save summary: $input.val()

        $editable = $input.closest('.editable')
        $editable.removeClass('in-edit')
        $editable.find('.show').html @ticket.get('summary')

    @$description.find('button[type="reset"]').click (e)->
      e.preventDefault()
      $input = $(e.target)
      $editable = $input.closest('.editable')
      $editable.removeClass('in-edit')

    @$description.find('button[type="submit"]').click (e)=>
      e.preventDefault()
      $textarea = @$description.find('textarea')
      @ticket.save description: $textarea.val()

      $editable = $textarea.closest('.editable')
      $editable.removeClass('in-edit')
      $editable.find('.show').html App.mdown(@ticket.get('description'))
