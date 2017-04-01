module ViewExtensionsHelper

  def render_props_fields(form, view_name)
    form.fields_for :props, form.object.props do |f|
      Houston.view[view_name].fields.map do |field|
        <<~HTML
          <hr />

          <div class="control-group">
            <label class="control-label" for="#{field.id}">#{field.label}</label>
            <div class="controls">
              #{field.render(self, f)}
            </div>
          </div>
        HTML
      end.join.html_safe
    end
  end

end
