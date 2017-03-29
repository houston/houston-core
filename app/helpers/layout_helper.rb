module LayoutHelper

  def layout_show_navigation?
    return true unless instance_variable_defined?(:@_layout_show_navigation)
    @_layout_show_navigation
  end

  def layout_container_fluid?
    return true unless instance_variable_defined?(:@_layout_container_fluid)
    @_layout_container_fluid
  end



  def render_layout_extensions(layout, type)
    partials = Houston.layout.extensions_by_layout[layout].public_send(type)
    partials.map { |block| instance_eval(&block) }.inject(&:+)
  end

end
