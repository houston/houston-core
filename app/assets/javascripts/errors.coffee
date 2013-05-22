class window.Errors
  
  constructor: (response)->
    if response.status == 401
      if response.getResponseHeader('X-Credentials') == 'Missing Credentials'
        @missingCredentials = true
      else if response.getResponseHeader('X-Credentials') == 'Invalid Credentials'
        @invalidCredentials = true
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
    alert = """
      <div class="alert alert-block alert-error">
        <button class="close" data-dismiss="alert">×</button>
        <h4 class="alert-heading">Oh snap! You got an error!</h4>
        <p>#{sentences.join('<br />')}</p>
      </div>
      """
    $(alert)

Errors.fromResponse = (response)-> new Errors(response)