class @TableRowExpander

  setupForViews: (views)->
    @expandedView = null
    views.each (view)=>
      view.on 'expanding', => @onViewExpanding(view)

      view.expand = _.bind ->
          @trigger('expanding')
          @$el.addClass('expanded in-transition')
          @$expandedRow = @renderExpandedRow()
          @$expandedRow.slideDown =>
            @$el.removeClass('in-transition')
            @trigger('expanded')
        , view

      view.collapse = _.bind (speed)->
          return unless @$expandedRow

          finish = =>
            @$el.removeClass('expanded in-transition')
            @$expandedRow.closest('tr').remove()
            @$expandedRow = null

          if speed == 'fast'
            finish()
          else
            @$el.addClass('in-transition')
            @$expandedRow.slideUp(finish)
        , view

      view.$el.click (e)=>
        return if $(e.target).is('button, a, input')
        @expandOrCollapseView(view)

    $('.table-sortable').bind 'sortStart', => @collapseExpandedView('fast')

  expandOrCollapseView: (view)->
    return if view.$el.hasClass('in-transition')
    return if view.$el.hasClass('deleting')

    if view.$el.hasClass('expanded')
      view.collapse()
    else
      view.expand()

  onViewExpanding: (view)->
    @collapseExpandedView()
    @expandedView = view

  collapseExpandedView: (speed)->
    @expandedView.collapse(speed) if @expandedView
