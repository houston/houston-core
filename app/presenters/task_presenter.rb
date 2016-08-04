class TaskPresenter
  include UrlHelper

  attr_reader :tasks

  def initialize(tasks)
    @tasks = OneOrMany.new(tasks)
  end

  def as_json(*args)
    tasks = @tasks
    tasks = Houston.benchmark "[#{self.class.name.underscore}] Load objects" do
      tasks.includes(:ticket => :project).load
    end if tasks.is_a?(ActiveRecord::Relation)
    Houston.benchmark "[#{self.class.name.underscore}] Prepare JSON" do
      tasks.select(&:ticket).map(&method(:task_to_json))
    end
  end

  def task_to_json(task)
    ticket = task.ticket
    project = ticket.project
    { id: task.id,

      projectId: project && project.id,
      projectSlug: project && project.slug,
      projectTitle: project && project.name,
      projectColor: project && project.color,

      ticketSystem: project && project.ticket_tracker_name,
      ticketUrl: project && ticket.ticket_tracker_ticket_url,
      ticketNumber: ticket.number,
      ticketType: ticket.type.to_s.downcase.dasherize,
      ticketSequence: ticket.extended_attributes["sequence"],  # <-- embeds knowledge of Houston::Scheduler

      shorthand: task.shorthand,
      description: task.description,
      effort: task.effort,
      firstReleaseAt: task.first_release_at,
      firstCommitAt: task.first_commit_at,
      completedAt: task.completed_at }
  end

end
