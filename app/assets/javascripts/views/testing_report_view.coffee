class window.TestingReportView extends Backbone.View
  
  initialize: ->
    @tickets = @options.tickets
    @pie = '.testing-report-progress.pie'
    @render()
  
  render: ->
    @expandedView = null
    $el = $(@el)
    $ul = $el
    $ul.empty()
    @tickets.each (ticket)=>
      view = new TestingTicketView(ticket: ticket)
      view.on 'expanding', => @onViewExpanding(view)
      view.on 'testing_note:refresh', _.bind(@refreshPieGraph, @)
      $ul.appendView view
    
    $("[data-tester-id=#{window.userId}]").addClass('current-tester') if window.userId
    
    $table = $('table.testing-report-table')
    $table.tablesorter
      headers:
        '4': {sorter: 'text'}
    $table.bind 'sortStart', =>
      @collapseExpandedView('fast')
    
    @refreshPieGraph()
  
  onViewExpanding: (view)->
    @collapseExpandedView()
    @expandedView = view
  
  collapseExpandedView: (speed)->
    @expandedView.collapse(speed) if @expandedView
  
  refreshPieGraph: ->
    return if $(@pie).length == 0
    
    passes = 0
    fails = 0
    gaps = 0
    
    @tickets.each (ticket)=>
      ticket.testerVerdicts().each ({verdict})=>
        if verdict == 'failing'
          fails += 1 
        else if verdict == 'passing'
          passes += 1 
        else
          gaps += 1
    
    chart = new Highcharts.Chart
      chart:
        renderTo: $(@pie).attr('id')
        plotBackgroundColor: null
        plotBorderWidth: null
        plotShadow: false
        marginTop: 0
        marginRight: 0
        marginBottom: 0
        marginLeft: 0
      colors: ['#0A0', '#C11', '#efefef']
      credits:
        enabled: false
      title:
        text: null
      plotOptions:
        pie:
          animation: false
          shadow: false
          dataLabels:
            enabled: false
          states:
            hover:
              enabled: false
      series: [{
          type: 'pie'
          data: [['Passes', passes], ['Fails', fails], ['Not Tested', gaps]]
        }]
      tooltip:
        enabled: false
