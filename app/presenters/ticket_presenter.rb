class TicketPresenter
  include UrlHelper
  include MarkdownHelper
  
  class OneOrMany
    
    def initialize(one_or_many)
      @one_or_many = one_or_many
    end
    
    def map(&block)
      if @one_or_many.respond_to?(:map)
        @one_or_many.map(&block)
      else
        yield @one_or_many
      end
    end
    
  end
  
  def initialize(tickets)
    @tickets = OneOrMany.new(tickets)
  end
  
  def as_json(*args)
    @tickets.map do |ticket|
      { id: ticket.id,
        projectId: ticket.project.ticket_tracking_id,
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
        age: ticket.age,
        dueDate: ticket.due_date,
        ticketSystem: ticket.project.ticket_tracking_adapter,
        ticketUrl: ticket.ticket_system_ticket_url }
    end
  end
  
  def with_testing_notes
    @tickets.map do |ticket|
      { id: ticket.id,
        projectId: ticket.project.ticket_tracking_id,
        projectSlug: ticket.project.slug,
        projectTitle: ticket.project.name,
        projectColor: ticket.project.color,
        projectMaintainers: ticket.project.maintainers_ids,
        number: ticket.number,
        summary: ticket.summary,
        verdict: ticket.verdict.downcase,
        verdictsByTester: ticket.verdicts_by_tester_index,
        queue: ticket.queue,
        committers: ticket.committers,
        deployment: ticket.deployment,
        age: ticket.age,
        dueDate: ticket.due_date,
        ticketSystem: ticket.project.ticket_tracking_adapter,
        ticketUrl: ticket.ticket_system_ticket_url,
        
        minPassingVerdicts: ticket.min_passing_verdicts,
        testingNotes: TestingNotePresenter.new(ticket.testing_notes).as_json,
        commits: CommitPresenter.new(ticket.commits).as_json,
        releases: ReleasePresenter.new(ticket.releases).as_json,
        lastReleaseAt: ticket.last_release_at,
        description: mdown(ticket.description) }
    end
  end
  
end
