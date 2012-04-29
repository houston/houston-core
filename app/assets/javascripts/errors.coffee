class window.Errors
  
  constructor: (errors)->
    @errors = errors
  
  renderToAlert: ->
    sentences = []
    for attribute, messages of @errors
      sentences.push "#{attribute} #{messages[0]}"
    alert = """
      <div class="alert alert-block alert-error">
        <button class="close" data-dismiss="alert">×</button>
        <h4 class="alert-heading">Oh snap! You got an error!</h4>
        <p>#{sentences.join('<br />')}</p>
      </div>
      """
    $(alert)

Errors.fromResponseText = (responseText)-> new Errors(JSON.parse(responseText))