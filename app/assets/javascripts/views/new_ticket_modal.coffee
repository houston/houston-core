class @NewTicketModal
  
  constructor: (options)->
    @slug = options.slug
    @color = options.color
    @template = HandlebarsTemplates['new_ticket/modal']
  
  show: ->
    @$modal = $(@template(color: @color)).modal()
    @$modal.on 'hidden', => @$modal.remove()
    xhr = $.get "/projects/#{@slug}/tickets/new"
    xhr.success (data)=>
      view = new NewTicketView(data)
      view.render()
