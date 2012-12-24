module CommitHelper
  
  def format_commit(commit)
    message = commit.message
    message = format_with_tickets_linked(commit.project, message)
    message
  end
  
  def link_to_commit(commit)
    link_to commit.sha[0...8], github_commit_url(commit), target: "_blank"
  end
  
  def format_change(change)
    message = change.description
    message = format_with_tickets_linked(change.project, message)
    message
  end
  
  def format_with_tickets_linked(project, message)
    message = h(message)
    
    message.gsub! Commit::TICKET_PATTERN do |match|
      ticket_number = Commit::TICKET_PATTERN.match(match)[1]
      link_to match, project.ticket_system_ticket_url(ticket_number), "target" => "_blank"
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
