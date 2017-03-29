class @Houston.NestedRow extends Neat.ModelEditor
  tagName: 'li'
  className: 'nested-row'

  context: ->
    context = super
    context.index = @index
    context

  destroy: (e)->
    e?.preventDefault()
    @$el.addClass('hidden')
    @model.set('destroyed', true)



class @Houston.NestedResources extends Neat.CollectionEditor
  modelView: Houston.NestedRow
  pageSize: Infinity
  index: 0

  initialize: (options)->
    super
    @collection.bind 'reset add change', @showOrHideAdd, @
    $(@el).delegate 'a.add-nested-link', 'click', _.bind(@addResource, @)

  afterRender: ->
    super
    @showOrHideAdd()

  addResource: (e)->
    e?.preventDefault()
    @collection.add new @collection.model()

  constructModelView: (options)->
    view = super(options)
    view.index = (@index += 1)
    view

  showOrHideAdd: ->
    visibleLinks = @$el.find('.nested-row:visible .add-nested').toArray()
    lastLink = visibleLinks.pop()
    $(visibleLinks).hide()
    $(lastLink).show()
