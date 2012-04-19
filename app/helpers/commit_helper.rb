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
    feature, sentence = message.split(":", 2)
    sentence ? "<b>#{feature}:</b>#{sentence}".html_safe : message
  end
  
  def format_with_tickets_linked(project, message)
    message.gsub Commit::TICKET_PATTERN do |match|
      ticket_number = Commit::TICKET_PATTERN.match(match)[1]
      link_to match, unfuddle_ticket_url(project, ticket_number)
    end.html_safe
  end
  
end
