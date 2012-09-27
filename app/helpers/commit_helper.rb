module CommitHelper
  
  def format_commit(commit)
    message = format_with_feature_bolded(commit.message)
    message = format_with_tickets_linked(commit.project, message)
    message
  end
  
  def format_change(change)
    message = format_with_feature_bolded(change.description)
    message = format_with_tickets_linked(change.project, message)
    message
  end
  
  def format_with_feature_bolded(message)
    feature = (message.match(/^([^\{:]+):/) || [])[1]
    if feature
      message = h(message[feature.length..-1])
      feature = "<b>#{h feature}:</b>"
    end
    "#{feature}#{message}".html_safe
  end
  
  def format_with_tickets_linked(project, message)
    message = h(message)
    
    message.gsub! Commit::TICKET_PATTERN do |match|
      ticket_number = Commit::TICKET_PATTERN.match(match)[1]
      link_to match, unfuddle_ticket_url(project, ticket_number), "target" => "_blank"
    end
    
    message.gsub! Commit::EXTRA_ATTRIBUTE_PATTERN do |match|
      key, value = match.scan(Commit::EXTRA_ATTRIBUTE_PATTERN).first
      link_to_err(project, value) if key == "err"
    end
    
    message.html_safe
  end
  
  def link_to_err(project, err)
    link_to errbit_err_url(project, err), "target" => "_blank" do
      image_tag image_url("bug-fixed-32.png"), "data-tooltip-placement" => "right", :rel => "tooltip", :title => "View Exception in Errbit", :width => 16, :height => 16
    end
  end
  
end
