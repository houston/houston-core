window.App =

  cable: ActionCable.createConsumer()

  play: (url)->
    audio = new Audio(url)
    audio.addEventListener "canplaythrough", -> audio.play()
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

  confirmDelete: (options)->
    html = """
    <div class="modal hide">
      <form class="form-horizontal" action="#{options.url}" method="POST">
        <input type="hidden" name="_method" value="delete">
        <input type="hidden" name="#{App.meta('csrf-param')}" value="#{App.meta('csrf-token')}">
        <div class="modal-header">
          <button type="button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button>
          <h3>Delete #{options.resource}</h3>
        </div>
        <div class="modal-body">
          #{options.message}
        </div>
        <div class="modal-footer">
          <button data-dismiss="modal" class="btn btn-default">Cancel</button>
          <button type="submit" class="btn btn-danger">Delete #{options.resource}</button>
        </div>
      </form>
    </div>
    """
    $modal = $(html).modal()
    $modal.on 'hidden', -> $(@).remove()

window.Houston = window.App
