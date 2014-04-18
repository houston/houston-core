class @ProblemsView extends Backbone.View
  
  initialize: ->
    @project = @options.project
    @problems = @options.problems
    @template = HandlebarsTemplates['problems/index']
    renderProblem = HandlebarsTemplates['problems/show']
    Handlebars.registerPartial 'problem', renderProblem

  render: ->
    $('#problems').html @template(problems: @problems)
    @updateProblemCount()
    
    $('#exceptions table').tablesorter
      headers:
        2: {sorter: 'timestamp'}
        3: {sorter: 'timestamp'}
    
    $('#exceptions').on 'click', '.btn-new-ticket', (e)=>
      $button = $(e.target)
      $button.attr('disabled', 'disabled')
      $exception = $button.closest('.exception')
      token = $exception.attr('data-token')
      App.showNewTicket
        type: 'bug'
        antecedents: ["Errbit: #{token}"]
        onClose: ->
          $button.removeAttr('disabled')
        onCreate: (ticket, modal)=>
          modal.modal('hide')
          $exception.addClass('has-ticket')
          @updateProblemCount()
  
  updateProblemCount: ->
    $('#problem_count').html $('.exception:not(.has-ticket)').length
