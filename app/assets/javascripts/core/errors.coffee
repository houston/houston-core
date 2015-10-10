class window.Errors

  constructor: (response)->
    if response.status == 401
      if response.getResponseHeader('X-Credentials') == 'Missing Credentials'
        @missingCredentials = true
      else if response.getResponseHeader('X-Credentials') == 'Invalid Credentials'
        @invalidCredentials = true
      else if response.getResponseHeader('X-Credentials') == 'Oauth'
        @oauthLocation = response.getResponseHeader('Location')
      else
        message = response.responseText ? "You are not authorized"
        @errors = {base: [message]}
    else
      @errors = JSON.parse(response.responseText)

  renderToAlert: ->
    sentences = []
    for attribute, messages of @errors
      if attribute == "base"
        sentences.push messages[0]
      else
        sentences.push "#{attribute} #{messages[0]}"
    alertify.error sentences.join(".\n")

Errors.fromResponse = (response)-> new Errors(response)