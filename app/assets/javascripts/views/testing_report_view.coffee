class window.TestingReportView extends Backbone.View
  
  initialize: ->
    @tickets = @options.tickets
    @projectsCanCloseTicketsFor = @options.projectsCanCloseTicketsFor
    @tickets.bind 'reset', _.bind(@render, @)
    
    # Prevent tablesorter from exhuming buried rows
    @tickets.bind 'destroy', (ticket)=>
      $('table.testing-report-table').trigger('update')
      
    @render()
  
  render: ->
    @expandedView = null
    $el = $(@el)
    $ul = $el
    $ul.empty()
    @tickets.each (ticket)=>
      view = new TestingTicketView
        ticket: ticket
        canClose: _.include(@projectsCanCloseTicketsFor, ticket.get('projectId'))
      view.on 'expanding', => @onViewExpanding(view)
      $ul.appendView view
    
    $("[data-tester-id=#{window.userId}]").addClass('current-tester') if window.userId
    
    $table = $('table.testing-report-table')
    $table.tablesorter(headers: {'4': {sorter: 'text'}})
    $table.bind 'sortStart', =>
      @collapseExpandedView('fast')
  
  onViewExpanding: (view)->
    @collapseExpandedView()
    @expandedView = view
  
  collapseExpandedView: (speed)->
    @expandedView.collapse(speed) if @expandedView
