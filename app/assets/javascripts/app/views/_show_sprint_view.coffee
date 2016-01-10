class @ShowSprintView extends Backbone.View

  initialize: ->
    @sprintId = @options.sprintId
    @sprintStart = @options.sprintStart
    @height = @options.height ? 260
    @template = HandlebarsTemplates['sprints/show']
    @tasks = _.sortBy @options.sprintTasks, (task)-> task.projectTitle
    super

  setStart: (@sprintStart)-> @
  setTasks: (sprintTasks)->
    @tasks = _.sortBy sprintTasks, (task)-> task.projectTitle
    @

  render: ->
    return @ unless @tasks
    for task in @tasks
      task.open = !task.completed

    @$el.html @template()
    @renderBurndownChart(@tasks)

  renderBurndownChart: (tasks)->

    # The time range of the Sprint
    today = new Date()
    monday = @sprintStart
    saturday = 2.days().before(monday)
    days = (i.days().after(saturday) for i in [0..6])

    # Sum progress by day;
    # Find the total amount of effort to accomplish
    committedByDay = {}
    completedByDay = {}
    totalEffort = 0
    for task in tasks
      effort = +task.effort
      if task.completed
        day = App.truncateDate App.parseDate(task.completedAt)
        effort = 0 if day < monday # this task was released before this sprint started!

        completedByDay[day] = (completedByDay[day] || 0) + effort
        committedByDay[day] = (committedByDay[day] || 0) + effort unless task.firstCommitAt

      if task.committed
        day = App.truncateDate App.parseDate(task.firstCommitAt)
        effort = 0 if day < monday # this task was released before this sprint started!

        committedByDay[day] = (committedByDay[day] || 0) + effort
      totalEffort += effort

    # for debugging
    window.completedByDay = completedByDay

    # Transform into remaining effort by day:
    # Iterate by day in case there are some days
    # where no progress was made
    toChartData = (progressByDay)->
      remainingEffort = totalEffort
      data = [
        day: saturday
        effort: Math.ceil(remainingEffort)
      ]
      for day in days
        unless day > today
          remainingEffort -= (progressByDay[day] || 0)
          data.push
            day: day
            effort: Math.ceil(remainingEffort)
      data

    committed = toChartData(committedByDay)
    completed = toChartData(completedByDay)
    toCommit = committed.last().effort
    toComplete = completed.last().effort

    new Houston.BurndownChart()
      .height(@height)
      .days(days)
      .totalEffort(totalEffort)
      .addLine('committed', committed)
      .addLine('completed', completed)
      .render()

    $('body').toggleClass('green', totalEffort > 0 and (toCommit == 0 or toComplete == 0))
