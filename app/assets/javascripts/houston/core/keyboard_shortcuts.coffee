class Shortcuts

  constructor: ->
    @_shortcuts = []

  create: (keys, description, callback, action)->
    @describe(keys, description)
    Mousetrap.bind(keys, callback, action)

  describe: (keys, description)->
    keys = if keys instanceof Array then keys else [keys]
    @_shortcuts.push
      keys: keys,
      description: description

  toJSON: ->
    @_shortcuts

Houston.shortcuts = new Shortcuts()
