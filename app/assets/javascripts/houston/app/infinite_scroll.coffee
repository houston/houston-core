class @InfiniteScroll

  constructor: (options)->
    @$el = options.$el ? $('.infinite-scroll')
    @offset = options.offset ? 50
    @load = options.load
    @success = options.success
    @error = options.error

    @$window = $(window)
    @$document = $(document)
    @$window.scroll _.bind(@onScroll, @)

  onScroll: ->
    return if @$el.hasClass('loading') or @$el.hasClass('done')
    return unless @$el.is(':visible')
    return unless @$window.scrollTop() >= (@$document.height() - @$window.height() - @offset)

    @loadMore()

  loadMore: ->
    xhr = @load(@$el)
    return unless xhr

    @$el.addClass('loading')
    xhr.done (html, status, e)=>
      @$el.removeClass('loading')
      if html is "" or e?.status is 204
        @$el.addClass('done')
      else
        @$el.append(html)
      @success() if @success
    xhr.fail =>
      @$el.removeClass('loading')
      @error() if @error
