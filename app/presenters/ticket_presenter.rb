class TicketPresenter
  include UrlHelper
  
  def initialize(tickets)
    @tickets = tickets
  end
  
  def as_json(*args)
    if @tickets.is_a?(Ticket)
      ticket_as_json(@tickets)
    else
      @tickets.map(&method(:ticket_as_json))
    end
  end
  
  def with_testing_notes
    @tickets.map do |ticket|
      { id: ticket.id,
        testingNotes: TestingNotePresenter.new(ticket.testing_notes).as_json,
        commits: CommitPresenter.new(ticket.commits).as_json,
        releases: ReleasePresenter.new(ticket.releases).as_json,
        lastReleaseAt: ticket.last_release_at,
        projectId: ticket.project.unfuddle_id,
        projectSlug: ticket.project.slug,
        projectTitle: ticket.project.name,
        projectColor: ticket.project.color,
        unfuddleUrl: unfuddle_ticket_url(ticket),
        number: ticket.number,
        summary: ticket.summary,
        queue: ticket.queue,
        committers: ticket.committers,
        deployment: ticket.deployment,
        description: BlueCloth::new(ticket.description).to_html }
    end
  end
  
  def ticket_as_json(ticket)
    { id: ticket.id,
      projectId: ticket.project.unfuddle_id,
      projectSlug: ticket.project.slug,
      projectTitle: ticket.project.name,
      projectColor: ticket.project.color,
      number: ticket.number,
      summary: ticket.summary,
      verdict: ticket.verdict.downcase,
      verdictsByTester: ticket.verdicts_by_tester_index,
      queue: ticket.queue,
      committers: ticket.committers,
      deployment: ticket.deployment,
      age: ticket.age }
  end
  
end
