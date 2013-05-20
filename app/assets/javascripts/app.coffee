window.App = 
  
  meta: (name)->
    $("meta[name=\"#{name}\"]").attr('value')
  
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
  
  emojify: (string)->
    string.replace /:([a-z0-9\+\-_]+):/, (match, $1)->
      if _.contains(Emoji.names, $1)
        "<img alt=\"#{$1}\" height=\"20\" width=\"20\" src=\"#{App.relativeRoot()}/images/emoji/#{$1}.png\" class=\"emoji\" />"
      else
        match
  
  promptForCredentialsTo: (service)->
    html = """
    <div class="modal hide fade">
      <div class="modal-header">
        <button type="button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button>
        <h3>Log in to #{service}</h3>
      </div>
      <div class="modal-body">
        <form class="form-horizontal">
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
        </form>
      </div>
      <div class="modal-footer">
        <button type="submit" class="btn btn-primary">Sign in</button>
      </div>
    </div>
    """
    $modal = $(html).modal()
    $modal.on 'hidden', -> $(@).remove()
    $modal.on 'shown', (e)=>
      $modal.find('button[type="submit"]').click (e)=>
        e.preventDefault()
        $.put '/credentials',
          service: service
          login: $modal.find('#user_credentials_login').val()
          password: $modal.find('#user_credentials_password').val()
        $modal.modal('hide')
    