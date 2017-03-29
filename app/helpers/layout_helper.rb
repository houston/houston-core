module LayoutHelper

  def layout_show_navigation?
    return true unless instance_variable_defined?(:@_layout_show_navigation)
    @_layout_show_navigation
  end

  def layout_container_fluid?
    return true unless instance_variable_defined?(:@_layout_container_fluid)
    @_layout_container_fluid
  end

end
