$.fn.extend

  pseudoHover: ->
    $(@).addClass('unhovered').hover(
      -> $(@).addClass('hover').removeClass('unhovered'),
      -> $(@).removeClass('hover').addClass('unhovered'))

  appendView: (view)->
    el = @append(view.el)
    view.render()
    el

  prependView: (view)->
    el = @prepend(view.el)
    view.render()
    el

  serializeObject: ->
    o = {}
    a = @serializeArray()
    endsInArrayBrackets = /\[\]$/
    $.each a, ->
      if o[@name] && endsInArrayBrackets.test(@name)
        o[@name] = [o[@name]] unless o[@name].push
        o[@name].push(@value || '')
      else
        o[@name] = @value || ''
    o

  highlight: ->
    $(@).effect('highlight', {}, 1500)

  reset: ->
    $(@).each -> @reset()

  disable: ->
    $(@).find('input[type="submit"], input[type="reset"], button').attr('disabled', 'disabled').end()

  enable: ->
    $(@).find('input[type="submit"], input[type="reset"], button').removeAttr('disabled').end()

  getCursorPosition: ->
    input = @get(0)
    return unless input
    if input.selectionStart # Standard-compliant browsers
      input.selectionStart
    else if document.selection # IE
      input.focus()
      sel = document.selection.createRange()
      selLen = document.selection.createRange().text.length
      sel.moveStart 'character', -input.value.length
      sel.text.length - selLen

  putCursorAtEnd: ->
    @each ->
      $(@).focus()

      # If this function exists...
      if @setSelectionRange
        # ... then use it (Doesn't work in IE)

        # Double the length because Opera is inconsistent about whether a carriage return is one character or two. Sigh.
        len = $(@).val().length * 2

        @setSelectionRange(len, len)
      else

        # ... otherwise replace the contents with itself
        # (Doesn't work in Google Chrome)

        $(@).val($(@).val())

  insertAtCursor: (text)->
    textarea = @[0]

    # IE support
    if document.selection
      textarea.focus()
      sel = document.selection.createRange()
      sel.text = text

    # MOZILLA and others
    else if textarea.selectionStart || textarea.selectionStart == '0'
      startPos = textarea.selectionStart
      endPos = textarea.selectionEnd
      textarea.value = textarea.value.substring(0, startPos) + text + textarea.value.substring(endPos, textarea.value.length)
      textarea.selectionStart = startPos + text.length
      textarea.selectionEnd = startPos + text.length

    else
      textarea.value += text

  supportImages: ->
    $el = @

    $el.append '''
      <div class="drag-and-drop">
        Attach files or images by dragging &amp; dropping them or <a class="dz-selector">selecting them</a>.
      </div>
      <div class="upload-progress"></div>
      <div class="upload-error"></div>
    '''

    bucket = App.meta('s3-bucket')
    $el.dropzone
      maxFilesize: 13 # MB
      clickable: '.dz-selector'
      acceptedFiles: '.pdf,.zip,image/jpeg,image/png,image/gif'
      url: "//#{bucket}.s3.amazonaws.com"
      uploadprogress: (file, progress)->
        $el.find('.upload-progress').html "Uploading #{file.name} (#{progress.toFixed(0)}% complete)"

      complete: ->
        if @getUploadingFiles().length is 0 and @getQueuedFiles().length is 0
          $el.removeClass('uploading')

      error: (file, errorMessage)->
        $el.addClass('error')
        $el.find('.upload-error').html """
          <span class="message">#{errorMessage}</span>
          <a class="dz-selector">Try again</a>"
        """

      sending: (file, xhr, formData)=>
        $el.removeClass('error').addClass('uploading')
        $el.find('.upload-progress').html "Uploading #{file.name}..."
        $.ajax
          url: '/uploads/policies',
          data: {name: file.name, size: file.size, type: file.type},
          type: 'POST',
          async: false, # because we need this response before dropzone can continue
          success: (params)=>
            src = "https://s3.amazonaws.com/#{bucket}/#{params.key}"
            link_markdown = "[#{file.name}](#{src})"
            link_markdown = "!#{link_markdown}" unless _.contains(["application/pdf", "application/zip"], file.type)
            @.find('textarea').insertAtCursor link_markdown
            $.each params, (key, value)->
              formData.append(key, value)



$.extend

  # Extend jQuery with functions for PUT and DELETE requests.
  put: (url, data, callback, type)->
    if jQuery.isFunction(data)
      callback = data
      data = {}

    data = data || {}
    data['_method'] = 'put'
    jQuery.post(url, data, callback, type)

  destroy: (url, data, callback, type)->
    if jQuery.isFunction(data)
      callback = data
      data = {}

    data = data || {}
    data._method = 'delete'
    jQuery.post(url, data, callback, type)



$(document).ajaxSend (e, jqxhr, settings)->
  return if settings.type is 'GET'
  jqxhr.setRequestHeader 'X-CSRF-Token', App.meta('csrf-token')
