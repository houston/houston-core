class window.TestingTicketsView extends Backbone.View
  el: '#tickets'
  
  initialize: ->
    @tickets = @options.tickets
    @render()
  
  render: ->
    $el = $(@el)
    $ul = $el.find('ul.tickets-list')
    $ul.empty()
    @tickets.each (ticket)=>
      view = new TestingTicketView(ticket: ticket)
      view.on 'testing_note:refresh', _.bind(@refreshPieGraph, @)
      $ul.appendView view
    
    $count = $el.find('.testing-report-ticket-count')
    $count.html "#{@tickets.length} #{if @tickets.length == 1 then 'ticket' else 'tickets'}"
    
    $("[data-tester-id=#{window.userId}]").addClass('current-tester') if window.userId
    
    @refreshPieGraph()
  
  refreshPieGraph: ->
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
    
    id = $(@el).attr('id').replace('testing_report', 'progress')
    chart = new Highcharts.Chart
      chart:
        renderTo: id
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
