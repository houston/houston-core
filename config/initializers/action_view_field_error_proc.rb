module ClassMutator
  def add_css_class(*classes)
    existing = (self["class"] || "").split(/\s+/)
    self["class"] = existing.concat(classes).uniq.join(" ")
    self
  end
end

Nokogiri::XML::Node.send(:include, ClassMutator)

ActionView::Base.field_error_proc = Proc.new do |html_tag, instance|
  html = %(<div class="field_with_errors">#{html_tag}</div>).html_safe
  
  form_fields = %w{textarea input select}
  elements = Nokogiri::HTML::DocumentFragment.parse(html_tag).css "label, " + form_fields.join(", ")
  
  elements.each do |e|
    if e.node_name.eql? "label" 
      html = e.add_css_class("error").to_s.html_safe
    elsif form_fields.include? e.node_name
      html = e.add_css_class("error").to_s.html_safe
      if instance.error_message.kind_of?(Array)
        html << "<span class=\"help-inline\">&nbsp;#{instance.error_message.join(", ")}</span>".html_safe
      else
        html << "<span class=\"help-inline\">&nbsp;#{instance.error_message}</span>".html_safe
      end
    end
  end
  html
end
