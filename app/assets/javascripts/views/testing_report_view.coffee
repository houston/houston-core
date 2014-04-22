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
    $el = $(@el)
    $ul = $el
    $ul.empty()
    views = @tickets.map (ticket)=>
      view = new TestingTicketView
        ticket: ticket
        canClose: _.include(@projectsCanCloseTicketsFor, ticket.get('projectId'))
      $ul.appendView view
      view
    
    @setupExpandableViews(views)
    
    $("[data-tester-id=#{window.userId}]").addClass('current-tester') if window.userId
    
    $table = $('table.testing-report-table')
    $table.tablesorter(headers: {'4': {sorter: 'text'}})
    $table.bind 'sortStart', =>
      @collapseExpandedView('fast')
  
  
  
  
  setupExpandableViews: (views)->
    @expandedView = null
    views.each (view)=>
      view.on 'expanding', => @onViewExpanding(view)
  
  onViewExpanding: (view)->
    @collapseExpandedView()
    @expandedView = view
  
  collapseExpandedView: (speed)->
    @expandedView.collapse(speed) if @expandedView
