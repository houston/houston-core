class @KeyboardShortcutsModal

  constructor: ->
    @template = HandlebarsTemplates['keyboard_shortcuts']

  show: ->
    $modal = $(@template(shortcuts: Houston.shortcuts.toJSON())).modal()
    $modal.on 'hidden', -> $modal.remove()

KeyboardShortcutsModal.show = ->
  new KeyboardShortcutsModal().show()
