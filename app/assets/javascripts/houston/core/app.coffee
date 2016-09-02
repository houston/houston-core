window.App =

  cable: ActionCable.createConsumer()

  play: (url)->
    audio = new Audio(url)
    audio.addEventListener "canplaythrough", ->
      # Wait 1 second before playing the sound effect
      # because Chromium on Raspbian will cut off the
      # first second of any sound effect :-(
      window.setTimeout (-> audio.play()), 1000
    audio.load()

  meta: (name)->
    $("meta[name=\"#{name}\"]").attr('content')

  serverDateFormat: d3.time.format('%Y-%m-%d')
  serverTimeFormat: d3.time.format.iso

  parseDate: (date)->
    return date unless _.isString(date)
    @serverDateFormat.parse date.slice(0, 10)

  parseTime: (time)->
    return time unless _.isString(time)
    @serverTimeFormat.parse time

  checkRevision: (jqXHR)->
    @clientRevision ||= App.meta('revision')
    serverRevision = jqXHR.getResponseHeader('X-Revision')
    if serverRevision
      if (@clientRevision != serverRevision)
        window.console.log("[App.checkRevision] reloading ('#{@clientRevision}' != '#{serverRevision}')")
        window.location.reload()
    else
      window.console.log("[App.checkRevision] serverRevision is blank")

  relativeRoot: ->
    relativeRoot = App.meta('relative_url_root')
    relativeRoot = relativeRoot.substring(0, relativeRoot.length - 1) if /\/$/.test(relativeRoot)
    relativeRoot

  mdown: (markdown)->
    return '' unless markdown
    converter = new showdown.Converter
      literalMidWordUnderscores: true
      strikethrough: true
      ghCodeBlocks: true
    html = converter.makeHtml(markdown)
    App.emojify(html)

  emojify: (string)->
    string.replace /:([a-z0-9\+\-_]+):/, (match, $1)->
      if _.contains(Emoji.names, $1)
        "<img alt=\"#{$1}\" height=\"20\" width=\"20\" src=\"#{App.relativeRoot()}/images/emoji/#{$1}.png\" class=\"emoji\" />"
      else
        match

  formatTicketSummary: (message)->
    message = Handlebars.Utils.escapeExpression(message)
    [feature, sentence] = message.split(':', 2)
    if sentence then "<b>#{feature}:</b>#{sentence}" else message

  formatPercent: (number)->
    (number * 100).toFixed(0) + '%'

  showErrorMessage: (title, responseText)->
    html = """
    <div class="modal hide">
      <div class="modal-header">
        <button type="button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button>
        <h3>#{title}</h3>
      </div>
      <div class="modal-body">
        #{responseText}
      </div>
      <div class="modal-footer">
        <button type="button" data-dismiss="modal">Close</button>
      </div>
    </div>
    """
    $modal = $(html).modal()
    $modal.on 'hidden', -> $(@).remove()

  uploadComplete: (id, args...)->
    $(id).trigger('upload:complete', args)

  toggleFullScreen: ->
    $body = $('body')

    $body.keypress (e)->
      if e.which is 102 # f
        $body.toggleClass('full-screen')
        window.location.hash = $body.attr('class')
        kanbanObj.setKanbanHeight() if window.kanbanObj # TMI: extract to event

    $body.keydown (e)->
      if e.keyCode is 27
        $body.removeClass('full-screen')
        window.location.hash = ''
        kanbanObj.setKanbanHeight() if window.kanbanObj # TMI: extract to event

    options = window.location.hash.substring(1).split(' ')
    if _.include(options, 'full-screen')
      $body.toggleClass('full-screen')
      kanbanObj.setKanbanHeight() if window.kanbanObj # TMI: extract to events

  showNewTicket: (options)->
    options ?= {}
    $banner = $('.project-banner')
    slug = $banner.attr('data-project-slug')
    color = $banner.attr('data-project-color')
    if slug and $('#new_ticket_modal').length is 0
      new NewTicketModal(_.extend(options, slug: slug, color: color)).show()

  oauth: (url)->
    window.location = url

  truncateDate: (date)->
    return date unless date.setHours
    date.setHours(0)
    date.setMinutes(0)
    date.setSeconds(0)
    date.setMilliseconds(0)
    date

  truncatedDate: (date)->
    date = new Date(date.getTime())
    App.truncateDate(date)

  showTicket: (number, project, options)->
    project = project || $('.project-banner').attr('data-project-slug')
    return false unless number and project

    options ||= {}
    options.project = project
    $context = options.$context || $('#tickets')
    numbers = _.map($context.find('[rel="ticket"]:visible'), (el)-> +$(el).attr('data-number'))
    options.ticketNumbers = numbers if numbers.length > 0
    options.edit = window.user.canEditTickets() if window.user
    new TicketModalView(options).show(number)

  promptForCredentialsTo: (service)->
    html = """
    <div class="modal hide fade">
      <form class="form-horizontal" id="user_credentials_form">
        <div class="modal-header">
          <button type="button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button>
          <h3>Log in to #{service}</h3>
        </div>
        <div class="modal-body">
          <div class="control-group">
            <label class="control-label" for="user_credentials_login">Login</label>
            <div class="controls">
              <input type="text" id="user_credentials_login">
            </div>
          </div>
          <div class="control-group">
            <label class="control-label" for="user_credentials_password">Password</label>
            <div class="controls">
              <input type="password" id="user_credentials_password">
            </div>
          </div>
        </div>
        <div class="modal-footer">
          <button type="submit" class="btn btn-primary">Sign in</button>
        </div>
      </form>
    </div>
    """
    $modal = $(html).modal()
    $modal.on 'hidden', -> $(@).remove()
    $modal.on 'shown', (e)=>
      $input = $modal.find('input[type="text"]:first').select()
      $modal.find('button[type="submit"]').click (e)=>
        e.preventDefault()
        xhr = $.put '/credentials',
          service: service
          login: $modal.find('#user_credentials_login').val()
          password: $modal.find('#user_credentials_password').val()
        xhr.success ->
          $modal.modal('hide')
        xhr.error (response)->
          $form = $('#user_credentials_form')
          $form.find('.alert').remove()
          Errors.fromResponse(response).renderToAlert().prependTo $form

window.Houston = window.App
