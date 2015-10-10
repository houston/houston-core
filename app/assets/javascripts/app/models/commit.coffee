class window.Commit extends Backbone.Model


class window.Commits extends Backbone.Collection
  model: Commit

  initialize: (models, options)->
    super(models, options)
    @ticket = options.ticket
