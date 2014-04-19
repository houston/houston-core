class @ProblemsView extends Backbone.View
  
  initialize: ->
    @project = @options.project
    @problems = @options.problems
    @template = HandlebarsTemplates['problems/index']
    @renderProblem = HandlebarsTemplates['problems/show']
    Handlebars.registerPartial 'problem', @renderProblem

  render: ->
    @refresh()
    
    $('#problems').on 'click', 'tr', _.bind(@toggleCheckbox, @)
    $('#problems').on 'click', ':checkbox', _.bind(@styleRow, @)
    
    $('#merge_exceptions').click _.bind(@mergeExceptions, @)
    $('#unmerge_exceptions').click _.bind(@unmergeExceptions, @)
    $('#delete_exceptions').click _.bind(@deleteExceptions, @)
    
    $('#exceptions table').tablesorter
      headers:
        2: {sorter: 'timestamp'}
        3: {sorter: 'timestamp'}
    
    $('#exceptions').on 'click', '.btn-new-ticket', (e)=>
      $button = $(e.target)
      $button.attr('disabled', 'disabled')
      $exception = $button.closest('.exception')
      token = $exception.attr('data-token')
      url = $exception.attr('data-url')
      problem = _.find(@problems, (problem)-> problem.url == url)
      return unless problem
      App.showNewTicket
        type: 'bug'
        antecedents: ["Errbit: #{token}"]
        onClose: ->
          $button.removeAttr('disabled')
        onCreate: (ticket, modal)=>
          modal.modal('hide')
          problem.ticketId = ticket.id
          problem.ticketUrl = ticket.url
          problem.ticketNumber = ticket.number
          @refresh()
  
  refresh: ->
    $('#problems').html @template(problems: @problems)
    @updateProblemCount()
  
  updateProblemCount: ->
    $('#problem_count').html $('.exception:not(.has-ticket)').length

  toggleCheckbox: (e)->
    return if _.include(['A', 'INPUT', 'BUTTON', 'TEXTAREA'], e.target.nodeName)
    $exception = $(e.target).closest('.exception')
    $checkbox = $exception.find(':checkbox')
    $checkbox.prop('checked', !$checkbox.prop('checked'))
    $exception.toggleClass('selected', $checkbox.is(':checked'))

  styleRow: (e)->
    $checkbox = $(e.target)
    $exception = $checkbox.closest('.exception')
    $exception.toggleClass('selected', $checkbox.is(':checked'))



  mergeExceptions: ->
    problems = @selectedProblems()
    if problems.length < 2
      @alert '#merge_exceptions', 'You must select at least two problems to merge'
    else
      $.post "/projects/#{@project}/exceptions/merge_several", problems: problems
      window.location.reload()

  unmergeExceptions: ->
    problems = @selectedProblems()
    if problems.length < 2
      @alert '#unmerge_exceptions', 'You must select at least one problem to unmerge'
    else
      $.post "/projects/#{@project}/exceptions/unmerge_several", problems: problems
      window.location.reload()

  deleteExceptions: ->
    problems = @selectedProblems()
    if problems.length < 2
      @alert '#delete_exceptions', 'You must select at least one problem to delete'
    else
      $.post "/projects/#{@project}/exceptions/delete_several", problems: problems
      window.location.reload()

  selectedProblems: ->
    $('#problems_form').serializeObject()['problems[]'] || []
  
  alert: (button, message)->
    $(button)
      .attr('data-content', message)
      .attr('data-trigger', 'manual')
      .attr('data-placement', 'top')
      .popover('show')
      .blur -> $(@).popover('hide')
