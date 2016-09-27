$ ->

  Houston.shortcuts.create "?", "Show this dialog box", (e) ->
    e.preventDefault()
    KeyboardShortcutsModal.show()

  $('#keyboard_shortcuts_button').click (e)->
    e.preventDefault()
    KeyboardShortcutsModal.show()
