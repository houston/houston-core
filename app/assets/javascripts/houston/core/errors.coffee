class window.Errors

  constructor: (response)->
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
