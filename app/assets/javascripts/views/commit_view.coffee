class window.CommitView extends Backbone.View
  tagName: 'li'
  className: 'commit'
  
  initialize: ->
    @renderer = Handlebars.compile($('#commit_template').html())
  
  render: ->
    $el = $(@el)
    $el.html @renderer(@model.toJSON())
    @
