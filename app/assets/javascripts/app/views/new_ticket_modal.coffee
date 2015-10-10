class @NewTicketModal

  constructor: (options)->
    @slug = options.slug
    @color = options.color
    @options = options
    @template = HandlebarsTemplates['new_ticket/modal']

  show: ->
    @$modal = $(@template(color: @color)).modal()
    @$modal.on 'hidden', =>
      @$modal.remove()
      @options.onClose() if @options.onClose

    xhr = $.get "/projects/#{@slug}/tickets/new"
    xhr.success (data)=>
      options = _.extend(data, @options)
      options.onCreate = ((ticket)=> @options.onCreate(ticket, @$modal)) if options.onCreate
      view = new NewTicketView(options)
      view.render()

      $('#reset_ticket').click (e)=>
        e.preventDefault()
        @$modal.modal('hide')
