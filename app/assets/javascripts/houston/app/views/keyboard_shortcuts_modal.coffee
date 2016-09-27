class @KeyboardShortcutsModal

  constructor: ->
    @template = HandlebarsTemplates['keyboard_shortcuts']
    @shortcuts = [
        keys: ['?']
        name: 'Keyboard shortcuts'
    ]

  show: ->
    $modal = $(@template(shortcuts: @shortcuts)).modal()
    $modal.on 'hidden', -> $modal.remove()
