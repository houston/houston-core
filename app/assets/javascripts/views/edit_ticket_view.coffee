class @EditTicketView extends Backbone.View

  initialize: ->
    @ticket = @options.ticket

  render: ->
    @$el.find('.editable').pseudoHover()
    @$summary = @$el.find('#ticket_summary')
    @$description = @$el.find('#ticket_description')

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
