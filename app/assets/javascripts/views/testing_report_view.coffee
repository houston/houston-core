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
    @$el.empty()
    views = @tickets.map (ticket)=>
      view = new TestingTicketView
        ticket: ticket
        canClose: _.include(@projectsCanCloseTicketsFor, ticket.get('projectId'))
      @$el.appendView view
      view
    
    @setupExpandableViews(views)
    
    $("[data-tester-id=#{window.userId}]").addClass('current-tester') if window.userId
    
    $('table.testing-report-table').tablesorter
      headers: {'4': {sorter: 'text'}}
  
  
  
  setupExpandableViews: (views)->
    @expandedView = null
    views.each (view)=>
      view.on 'expanding', => @onViewExpanding(view)
      view.$el.click (e)=>
        return if $(e.target).is('button, a, input')
        @expandOrCollapseView(view)
    
    $('.table-sortable').bind 'sortStart', => @collapseExpandedView('fast')
  
  expandOrCollapseView: (view)->
    return if view.$el.hasClass('in-transition')
    return if view.$el.hasClass('deleting')

    if view.$el.hasClass('expanded')
      view.collapse()
    else
      view.expand()
  
  onViewExpanding: (view)->
    @collapseExpandedView()
    @expandedView = view
  
  collapseExpandedView: (speed)->
    @expandedView.collapse(speed) if @expandedView
