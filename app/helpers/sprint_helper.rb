module SprintHelper

  def format_sprint_time_frame(sprint)
    if sprint.start_date.month == sprint.end_date.month
      "#{sprint.start_date.strftime("%b %-d")}&ndash;#{sprint.end_date.strftime("%-d")}".html_safe
    else
      "#{sprint.start_date.strftime("%b %-d")} &ndash; #{sprint.end_date.strftime("%b %-d")}".html_safe
    end
  end

end
