Houston::Slack.config do
  overhear(/\b(?<task>\d+[a-z]+)\b/) do |e|
    next unless e.user && e.user.developer?
    tasks = Task.joins(:ticket)

    if project = e.channel.name != "test" && Project.find_by_slug(e.channel.name)
      tasks = tasks.where(Ticket.arel_table[:project_id].eq(project.id))
    else
      tasks = tasks.merge(Ticket.open)
    end

    tasks.with_shorthand(e.match[:task]).each do |task|
      e.unfurl slack_task_attachment(task)
    end
  end
end
