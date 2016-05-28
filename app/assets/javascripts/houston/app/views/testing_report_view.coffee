class window.TestingReportView extends Backbone.View

  initialize: ->
    @tickets = @options.tickets
    @projectsCanCloseTicketsFor = @options.projectsCanCloseTicketsFor
    @tickets.bind 'reset', _.bind(@render, @)
    @expander = new TableRowExpander()

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

    @expander.setupForViews views

    $("[data-tester-id=#{window.userId}]").addClass('current-tester') if window.userId

    $('table.testing-report-table').tablesorter
      headers: {'4': {sorter: 'text'}}
