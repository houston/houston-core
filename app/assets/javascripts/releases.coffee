$ ->
  $nestedEditor = $('.changes-nested-editor')
  $nestedEditor.delegate '.change-description input', 'keypress', (e)->
    if e.keyCode == 13
      e.preventDefault()
      e.stopImmediatePropagation()
      FT.addNestedRow(FT.getNestedRowFromEvent(e));
  $nestedEditor.delegate '.change-description input', 'keyup', (e)->
    if e.keyCode == 8 and $(this).val() == ''
      e.preventDefault()
      e.stopImmediatePropagation()
      FT.deleteNestedRow(FT.getNestedRowFromEvent(e));      
