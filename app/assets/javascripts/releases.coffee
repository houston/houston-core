window.App.NewReleaseForm =
  
  init: ->
    $nestedEditor = $('.changes-nested-editor')
    $nestedEditor.find('.add-link').attr('tabindex', '-1').html('<i class="icon-plus-sign"></i>')
    $nestedEditor.find('.delete-link').attr('tabindex', '-1').html('<i class="icon-minus-sign"></i>')
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
      if e.keyCode == 38
        $(this).closest('.nested-row').prev().find('input').select()
      if e.keyCode == 40
        $(this).closest('.nested-row').next().find('input').select()
