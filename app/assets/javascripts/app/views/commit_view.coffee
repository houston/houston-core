class window.CommitView extends Backbone.View
  tagName: 'li'
  className: 'commit'
  
  initialize: ->
    @renderer = HandlebarsTemplates['commit']
  
  render: ->
    $el = $(@el)
    json = @model.toJSON()
    json['message'] = json['message'].replace(/\[#(\d+)\]/g, '') # remove ticket numbers)
    $el.html @renderer(json)
    @
