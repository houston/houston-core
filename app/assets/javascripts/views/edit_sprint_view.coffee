class @EditSprintView extends @ShowSprintView
  
  events:
    'click .check-out-button': 'toggleCheckOut'
    'click #show_completed_tasks': 'toggleShowCompleted'
    'click #lock_sprint_button': 'confirmLockSprint'
    'click .remove-task-button': 'removeTask'
    'submit #add_task_form': 'submitAddTaskForm'
  
  initialize: ->
    super
    @sprintStart = @options.sprintStart
    @locked = @options.sprintLocked
    @template = HandlebarsTemplates['sprints/edit']
    @typeaheadTemplate = HandlebarsTemplates['sprints/typeahead']
    @openTasks = @options.openTasks
  
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
    $modal.find('#task_effort').focus()
    $modal.on 'hidden', ->
      $modal.remove()
      $('#add_task').focus()
    $modal.on 'keypress', 'input[type="number"]', (e)->
      return if e.keyCode in [13, 27] # <-- allow Enter and Escape
      value = $(e.target).val() + String.fromCharCode(e.charCode)
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
          <i class="fa fa-lock" /> Lock It!
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
      .html('<i class="fa fa-lock" /> Locked')
