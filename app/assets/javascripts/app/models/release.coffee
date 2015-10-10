class window.Release extends Backbone.Model


class window.Releases extends Backbone.Collection
  model: Release

  initialize: (models, options)->
    super(models, options)
    @ticket = options.ticket
