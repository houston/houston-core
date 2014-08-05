class @ShowSprintView extends Backbone.View
  
  initialize: ->
    @sprintId = @options.sprintId
    @sprintStart = @options.sprintStart
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
      task.completed = !!task.firstReleaseAt || !!task.firstCommitAt
      task.open = !task.completed
    
    @$el.html @template()
    @renderBurndownChart(@tasks)
  
  renderBurndownChart: (tasks)->
    
    # The time range of the Sprint
    tomorrow = 1.day().after(new Date())
    monday = @sprintStart
    days = (i.days().after(monday) for i in [0..4])
    
    # Sum progress by day;
    # Find the total amount of effort to accomplish
    committedByDay = {}
    completedByDay = {}
    totalEffort = 0
    for task in tasks
      effort = +task.effort
      if task.firstReleaseAt
        day = App.truncateDate App.parseDate(task.firstReleaseAt)
        effort = 0 if day < monday # this task was released before this sprint started!
        
        day = 1.day().after(day)
        completedByDay[day] = (completedByDay[day] || 0) + effort
        committedByDay[day] = (committedByDay[day] || 0) + effort unless task.firstCommitAt
      
      if task.firstCommitAt
        day = App.truncateDate App.parseDate(task.firstCommitAt)
        effort = 0 if day < monday # this task was released before this sprint started!
        
        day = 1.day().after(day)
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
        day: monday
        effort: Math.ceil(remainingEffort)
      ]
      for day in days.slice(1)
        unless day > tomorrow
          remainingEffort -= (progressByDay[day] || 0)
          data.push
            day: day
            effort: Math.ceil(remainingEffort)
      data
    
    new Houston.BurndownChart()
      .selector('#graph')
      .days(days)
      .totalEffort(totalEffort)
      .addLine('committed', toChartData(committedByDay))
      .addLine('completed', toChartData(completedByDay))
      .render()
