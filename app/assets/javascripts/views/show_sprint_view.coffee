class @ShowSprintView extends Backbone.View
  
  events:
    'click .check-out-button': 'toggleCheckOut'
    'click #show_completed_tasks': 'toggleShowCompleted'
    'click #lock_sprint_button': 'confirmLockSprint'
    'click .remove-task-button': 'removeTask'
    'submit #add_task_form': 'submitAddTaskForm'
  
  initialize: ->
    @sprintId = @options.sprintId
    @sprintStart = @options.sprintStart
    @locked = @options.sprintLocked
    @template = HandlebarsTemplates['sprints/show']
    @typeaheadTemplate = HandlebarsTemplates['sprints/typeahead']
    @tasks = _.sortBy @options.sprintTasks, (task)-> task.projectTitle
    @openTasks = @options.openTasks
    super
  
  render: ->
    return @ unless @tasks
    for task in @tasks
      task.completed = !!task.firstReleaseAt || !!task.firstCommitAt
      task.open = !task.completed
    
    html = @template
      locked: @locked
      tasks: @tasks
      sprintId: @sprintId
    @$el.html html
    
    if @locked
      @showAsLocked()
    else
      @$el.addClass 'edit-mode'
      $('#add_task').focus()
    
    @renderBurndownChart(@tasks)
    @updateTotalEffort()
    
    typeaheadTemplate = @typeaheadTemplate
    view = @
    $add_task = @$el.find('#add_task').attr('autocomplete', 'off').typeahead
      source: @openTasks
      matcher: (item)->
        ~item.description.toLowerCase().indexOf(@query.toLowerCase()) ||
        ~item.projectTitle.toLowerCase().indexOf(@query.toLowerCase()) ||
        ~item.shorthand.toString().toLowerCase().indexOf(@query.toLowerCase())
      
      sorter: (items)-> items # apply no sorting (return them in order of priority)
      
      highlighter: (task)->
        query = @query.replace(/[\-\[\]{}()*+?.,\\\^$|#\s]/g, '\\$&')
        regex = new RegExp("(#{query})", 'ig')
        task.description.replace regex, ($1, match)-> "<strong>#{match}</strong>"
        typeaheadTemplate
          sequence: task.extendedAttributes?.sequence
          description: task.description.replace regex, ($1, match)-> "<strong>#{match}</strong>"
          shorthand: task.shorthand.toString().replace regex, ($1, match)-> "<strong>#{match}</strong>"
          projectTitle: task.projectTitle.replace regex, ($1, match)-> "<strong>#{match}</strong>"
          projectColor: task.projectColor
    
    $add_task.data('typeahead').render = (tasks)->
      items = $(tasks).map (i, item)=>
        i = $(@options.item).attr('data-value', item.id)
        i.find('a').html(@highlighter(item))
        i[0]
      
      items.first().addClass('active')
      @$menu.html(items)
      @
    
    addTask = _.bind(@addTask, @)
    $add_task.data('typeahead').select = ->
      id = @$menu.find('.active').attr('data-value')
      @$element.val('')
      @hide()
      addTask(id)
    
    
    
    $('.table-sortable').tablesorter()
    @
  
  
  
  submitAddTaskForm: (e)->
    e.preventDefault()
  
  addTask: (id)->
    task = _.detect @openTasks, (task)-> +task.id == +id
    if task && +task.effort <= 0
      @promptForEffort(task).done(=> @addTask(id))
      return
    
    $('#add_task_form').addClass('loading')
    
    $.post("/sprints/#{@sprintId}/tasks/#{id}")
      .error( (response) =>
        $('#add_task_form').removeClass('loading')
        $('#add_task')
          .tooltip
            animation: false
            title: response.responseText
            placement: 'bottom'
            trigger: 'manual'
          .tooltip('show')
        window.setTimeout((-> $('#add_task').tooltip('destroy')), 3000)

      ).success (task)=>
        @showCompletedTasks() if !task.open
        unless _.detect(@tasks, (_task)-> _task.id == task.id)
          @tasks.push task
          @rerenderTasks()
          @renderBurndownChart(@tasks)
        $(".task[data-task-id=#{task.id}]").highlight()
        $('#add_task_form').removeClass('loading')
  
  removeTask: (e)->
    $button = $(e.target)
    $task = $button.closest('.task')
    id = +$task.attr('data-task-id')
    $.destroy("/sprints/#{@sprintId}/tasks/#{id}")
      .error =>
        $task.removeClass('deleting')
      .success (task)=>
        @tasks = _.reject(@tasks, (task)-> task.id == id)
        $task.remove()
        @renderBurndownChart(@tasks)
    
  rerenderTasks: ->
    template = HandlebarsTemplates['sprints/task']
    $tasks = @$el.find('#tasks').empty()
    for task in @tasks
      task.completed = !!task.firstReleaseAt || !!task.firstCommitAt
      task.open = !task.completed
      $tasks.append template(task)
  
  promptForEffort: (task)->
    promise = $.Deferred()
    html = """
    <form class="modal hide">
      <div class="modal-header">
        <button type="button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button>
        <h3>Estimate Task ##{task.shorthand}</h3>
      </div>
      <div class="modal-body">
        <p>#{task.description}</p>
        <div style="text-align: right">
          <label for="task_effort">
            Effort:
            <input autofocus type="number" id="task_effort" class="ticket-effort" style="text-align: right; width: 80px;" />
          </label>
        </div>
      </div>
      <div class="modal-footer">
        <button class="btn btn-default" type="reset" data-dismiss="modal">Close</button>
        <button class="btn btn-primary" type="submit">Submit</button>
      </div>
    </form>
    """
    $modal = $(html).modal()
    $modal.on 'hidden', -> $modal.remove()
    $modal.on 'keypress', 'input[type="number"]', (e)->
      character = String.fromCharCode(e.charCode)
      value = $(e.target).val() + character
      e.preventDefault() unless /^\d+(\.\d{0,2})?$/.test(value)
      e.preventDefault() if +value > 999.99
    $modal.submit (e)->
      e.preventDefault()
      effort = +$('#task_effort').val()
      xhr = $.put "/tasks/#{task.id}", effort: effort
      xhr.success ->
        task.effort = effort
        promise.resolve()
        $modal.modal('hide')
      xhr.error ->
        $('#task_effort').focus()
        console.log('error', arguments)
    promise
  
  
  
  renderBurndownChart: (tasks)->
    
    # The time range of the Sprint
    today = new Date()
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
        completedByDay[day] = (completedByDay[day] || 0) + effort
        committedByDay[day] = (committedByDay[day] || 0) + effort unless task.firstCommitAt
      if task.firstCommitAt
        day = App.truncateDate App.parseDate(task.firstCommitAt)
        effort = 0 if day < monday # this task was released before this sprint started!
        committedByDay[day] = (committedByDay[day] || 0) + effort
      totalEffort += effort
    
    # for debugging
    window.completedByDay = completedByDay
    
    # Transform into remaining effort by day:
    # Iterate by day in case there are some days
    # where no progress was made
    remainingEffort = totalEffort - (completedByDay[monday] || 0)
    data1 = [
      day: monday
      effort: Math.ceil(remainingEffort)
    ]
    for day in days.slice(1)
      unless day > today
        remainingEffort -= (completedByDay[day] || 0)
        data1.push
          day: day
          effort: Math.ceil(remainingEffort)
    
    remainingEffort = totalEffort - (committedByDay[monday] || 0)
    data2 = [
      day: monday
      effort: Math.ceil(remainingEffort)
    ]
    for day in days.slice(1)
      unless day > today
        remainingEffort -= (committedByDay[day] || 0)
        data2.push
          day: day
          effort: Math.ceil(remainingEffort)
    
    margin = {top: 40, right: 80, bottom: 32, left: 50}
    width = 960 - margin.left - margin.right
    height = 320 - margin.top - margin.bottom
    formatDate = d3.time.format('%A')
    
    x = d3.scale.ordinal().rangePoints([0, width], 0.75).domain(days)
    y = d3.scale.linear().range([height, 0]).domain([0, totalEffort])
    
    xAxis = d3.svg.axis()
      .scale(x)
      .orient('bottom')
      .tickFormat((d)-> formatDate(new Date(d)))
    
    yAxis = d3.svg.axis()
      .scale(y)
      .orient('left')
    
    line = d3.svg.line()
      .interpolate('linear')
      .x((d)-> x(d.day))
      .y((d)-> y(d.effort))
    
    $('#graph').empty()
    svg = d3.select('#graph').append('svg')
        .attr('width', width + margin.left + margin.right)
        .attr('height', height + margin.top + margin.bottom)
      .append('g')
        .attr('transform', "translate(#{margin.left},#{margin.top})")
    
    svg.append('g')
      .attr('class', 'x axis')
      .attr('transform', "translate(0,#{height})")
      .call(xAxis)
    
    svg.append('g')
        .attr('class', 'y axis')
        .call(yAxis)
      .append('text')
        .attr('transform', 'rotate(-90)')
        .attr('y', -45)
        .attr('x', -160)
        .attr('dy', '.71em')
        .attr('class', 'legend')
        .style('text-anchor', 'end')
        .text('Points Remaining')
    
    
    
    svg.append('path')
      .attr('class', 'line line-committed')
      .attr('d', line(data2))
    
    svg.selectAll('circle.circle-committed')
      .data(data2)
      .enter()
      .append('circle')
        .attr('class', 'circle-committed')
        .attr('r', 5)
        .attr('cx', (d)-> x(d.day))
        .attr('cy', (d)-> y(d.effort))
    
    svg.selectAll('.effort-remaining.effort-committed')
      .data(data2)
      .enter()
      .append('text')
        .text((d) -> d.effort)
        .attr('class', 'effort-remaining effort-committed')
        .attr('transform', (d)-> "translate(#{x(d.day) + 5.5}, #{y(d.effort) - 10}) rotate(-75)")
    
    
    
    svg.append('path')
      .attr('class', 'line line-completed')
      .attr('d', line(data1))
    
    svg.selectAll('circle.circle-completed')
      .data(data1)
      .enter()
      .append('circle')
        .attr('class', 'circle-completed')
        .attr('r', 5)
        .attr('cx', (d)-> x(d.day))
        .attr('cy', (d)-> y(d.effort))
    
    svg.selectAll('.effort-remaining.effort-completed')
      .data(data1)
      .enter()
      .append('text')
        .text((d) -> d.effort)
        .attr('class', 'effort-remaining effort-completed')
        .attr('transform', (d)-> "translate(#{x(d.day) + 5.5}, #{y(d.effort) - 10}) rotate(-75)")
  
  
  
  toggleCheckOut: (e)->
    $button = $(e.target)
    $task = $button.closest('tr')
    id = +$task.attr('data-task-id')
    task = _.find @tasks, (task)-> task.id == id
    
    if $button.hasClass('active')
      @checkIn($button, $task, id, task)
    else
      @checkOut($button, $task, id, task)
  
  checkIn: ($button, $task, id, task)->
    $.destroy("/tasks/#{id}/lock")
      .success =>
        task.checkedOutAt = null
        task.checkedOutBy = null
        $button.removeClass('btn-danger').addClass('btn-info').html('Check out')
        @updateTotalEffort()
      .error (xhr)=>
        errors = Errors.fromResponse(response)
        errors.renderToAlert().appendAsAlert()
  
  checkOut: ($button, $task, id, task)->
    $.post("/tasks/#{id}/lock")
      .success =>
        task.checkedOutAt = new Date()
        task.checkedOutBy =
          id: window.user.id
          name: window.user.get('name')
          email: window.user.get('email')
        $button.removeClass('btn-info').addClass('btn-danger').html('Check in')
        @updateTotalEffort()
      .error (response)=>
        errors = Errors.fromResponse(response)
        errors.renderToAlert().appendAsAlert()

  updateTotalEffort: ->
    effort = 0
    for task in @tasks when task.checkedOutBy?.id == window.user.id
      effort += +task.effort
    $('#total_effort').html(effort.toFixed(1))


  toggleShowCompleted: (e)->
    $button = $(e.target)
    if $button.hasClass('active')
      $button.removeClass('btn-success')
      @$el.addClass('hide-completed')
    else
      $button.addClass('btn-success')
      @$el.removeClass('hide-completed')

  showCompletedTasks: ->
    $button = $('#show_completed_tasks')
    $button.addClass('active')
    $button.addClass('btn-success')
    @$el.removeClass('hide-completed')


  confirmLockSprint: ->
    return if @locked
    $modal = $("""
    <div class="modal hide" tabindex="-1">
      <div class="modal-header">
        <button type="button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button>
        <h3>Lock Sprint</h3>
      </div>
      <div class="modal-body">
        Once you lock a Sprint, you will be unable to add or remove tasks.
      </div>
      <div class="modal-footer">
        <button class="btn" data-dismiss="modal">Back away slowly</button>
        <button id="confirm_lock_sprint" class="btn btn-danger" data-dismiss="modal">
          <i class="icon icon-lock" /> Lock It!
        </button>
      </div>
    </div>
    """).modal()
    $modal.on 'hidden', -> $modal.remove()
    $('#confirm_lock_sprint').click _.bind(@lockSprint, @)
  
  lockSprint: ->
    $.put("/sprints/#{@sprintId}/lock")
      .success =>
        @locked = true
        @showAsLocked()
  
  showAsLocked: ->
    @$el.removeClass 'edit-mode'
    $('#lock_sprint_button')
      .attr('disabled', 'disabled')
      .addClass('active')
      .removeClass('btn-danger')
      .html('<i class="icon icon-lock" /> Locked')
