class @ReportsView extends Backbone.View

  render: ->
    @$el.html '''
      <h3>Queue Size and Ticket Age</h3>
      <div id="queue_age" class="graph"></div>

      <h3>Cycle Time (days)</h3>
      <div id="cycle_time" class="graph"></div>

      <h3>Time-to-Release (days)</h3>
      <div id="time_to_release" class="graph"></div>

      <h3>Time-to-First-Test (hours)</h3>
      <div id="time_to_first_test" class="graph"></div>
    '''
    $.getJSON "/reports/queue-age#{window.location.search}", (json)->
      new Houston.StackedAreaGraph()
        .selector('#queue_age')
        .labels(['0-3wks', '3wks–3mos', '3-9mos', '9mos–2yrs', '> 2yrs'])
        .colors([
          'rgb(31, 119, 180)',
          'rgb(71, 48, 129)',
          'rgb(175, 76, 143)',
          'rgb(236, 148, 52)',
          'rgb(243, 210, 35)'
        ])
        .data(json.data)
        .addLine(json.line)
        .render()

    $.getJSON "/reports/cycle-time#{window.location.search}", (data)->
      new Houston.StackedAreaGraph()
        .selector('#cycle_time')
        .labels(['cycle time'])
        .data(data)
        .render()

    $.getJSON "/reports/time-to-release#{window.location.search}", (data)->
      new Houston.StackedAreaGraph()
        .selector('#time_to_release')
        .labels(['time-to-close', 'time-to-release'])
        .data(data)
        .render()

    $.getJSON "/reports/time-to-first-test#{window.location.search}", (data)->
      new Houston.StackedAreaGraph()
        .selector('#time_to_first_test')
        .labels(['time-to-test'])
        .data(data)
        .render()
