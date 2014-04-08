module CommitHelper
  
  def format_commit(commit)
    message = commit.summary
    message = format_with_tickets_linked(commit.project, message)
    message = mdown(message)
    message
  end
  
  def link_to_commit(commit)
    project = commit.project
    short_sha = commit.sha[0...8]
    return short_sha unless github_url?(project)
    
    link_to short_sha, github_commit_url(project, commit.sha), target: "_blank"
  end
  
  def link_to_release_commit_range(release)
    return "" if release.commit0.blank? && release.commit1.blank?
    link_to_commit_range(release.project, release.commit0, release.commit1)
  end
  
  def link_to_commit_range(project, commit0, commit1)
    range = "#{format_sha(commit0)}<span class=\"ellipsis\">...</span>#{format_sha(commit1)}".html_safe
    return range unless github_url?(project)
    return range if commit0.blank? or commit1.blank?
    
    link_to range, github_commit_range_url(project, commit0, commit1), target: "_blank", title: "Compare"
  end
  
  def format_sha(sha)
    return "_"*8 if sha.blank?
    sha[0...7]
  end
  
  def format_change(change)
    message = change.description
    message = format_with_tickets_linked(change.project, message)
    message = mdown(message)
    message
  end
  
  def format_with_tickets_linked(project, message)
    message = h(message)
    
    message.gsub! Commit::TICKET_PATTERN do |match|
      ticket_number = Commit::TICKET_PATTERN.match(match)[1]
      link_to match, project.ticket_tracker_ticket_url(ticket_number), "target" => "_blank"
    end
    
    message.gsub! Commit::EXTRA_ATTRIBUTE_PATTERN do |match|
      key, value = match.scan(Commit::EXTRA_ATTRIBUTE_PATTERN).first
      link_to_err(project, value) if key == "err"
    end
    
    message.html_safe
  end
  
  def link_to_err(project, err)
    link_to project.error_tracker_error_url(err), "target" => "_blank" do
      image_tag image_url("bug-fixed-32.png"), "data-tooltip-placement" => "right", :rel => "tooltip", :title => "View Exception in Errbit", :width => 16, :height => 16
    end
  end
  
end
