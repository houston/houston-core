class TicketPresenter
  include UrlHelper
  include MarkdownHelper
  
  def initialize(tickets)
    @tickets = OneOrMany.new(tickets)
  end
  
  def as_json(*args)
    @tickets.map(&method(:ticket_to_json))
  end
  
  def ticket_to_json(ticket)
    project = ticket.project
    { id: ticket.id,
      projectSlug: project.slug,
      projectTitle: project.name,
      projectColor: project.color,
      number: ticket.number,
      summary: ticket.summary,
      type: ticket.type.to_s.downcase.dasherize,
      priority: ticket.priority,
      tags: ticket.tags.map(&:to_h),
      verdict: ticket.verdict.downcase,
      verdictsByTester: ticket.verdicts_by_tester_index,
      queue: ticket.queue,
      committers: ticket.committers(&:to_h),
      deployment: ticket.deployment,
      age: ticket.age,
      dueDate: ticket.due_date,
      ticketSystem: project.ticket_tracker_name,
      ticketUrl: ticket.ticket_tracker_ticket_url }
  end
  
  def with_extended_attributes
    @tickets.map do |ticket|
      ticket_to_json(ticket).merge({
        extendedAttributes: ticket.extended_attributes
      })
    end
  end
  
  def with_testing_notes
    @tickets.map do |ticket|
      ticket_to_json(ticket).merge({
        projectMaintainers: ticket.project.maintainers_ids,
        minPassingVerdicts: ticket.min_passing_verdicts,
        testingNotes: TestingNotePresenter.new(ticket.testing_notes).as_json,
        commits: CommitPresenter.new(ticket.commits).as_json,
        releases: ReleasePresenter.new(ticket.releases).as_json,
        lastReleaseAt: ticket.last_release_at,
        description: mdown(ticket.description) })
    end
  end
  
end
