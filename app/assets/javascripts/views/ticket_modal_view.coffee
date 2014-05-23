class @TicketModalView extends Backbone.View
  className: 'modal ticket-modal'

  initialize: ->
    @project = @options.project
    @ticketNumbers = @options.ticketNumbers
    @onClose = @options.onClose
    @template = HandlebarsTemplates['tickets/modal']
    @renderTicket = HandlebarsTemplates['tickets/show']
    @$el.attr('tabindex', -1) # so that ESC works
    
    if @ticketNumbers
      @count = @ticketNumbers.length
      Mousetrap.bind 'left',  (e)=> @show(@prev()) if @$el.is(':visible')
      Mousetrap.bind 'right', (e)=> @show(@next()) if @$el.is(':visible')

  show: (number)->
    return unless number
    $.get "/projects/#{@project}/tickets/by_number/#{number}.json", (json)=>
      @number = number
      @index = _.indexOf(@ticketNumbers, number) if @ticketNumbers
      @html = @renderTicket(json)
      @render()

  render: ->
    @$el.html @template
      ticket: @html
      index: @index + 1
      count: @count
    $modal = @$el.modal()
    $('body').addClass('noscroll')
    $modal.find('[title]').tooltip
      placement: 'bottom'
    $modal.on 'hidden', (e)->
      if $modal[0] == e.target
        $modal.remove()
        $('body').removeClass('noscroll')
        @onClose() if @onClose

  next: ->
    return @ticketNumbers[0] if @index >= (@count - 1)
    @ticketNumbers[@index + 1]

  prev: ->
    return @ticketNumbers[@count - 1] if @index <= 0
    @ticketNumbers[@index - 1]
