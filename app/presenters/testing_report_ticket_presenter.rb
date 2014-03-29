class TestingReportTicketPresenter
  include UrlHelper
  include MarkdownHelper
  
  def initialize(tickets)
    @tickets = tickets
      .unclosed
      .fixed
      .deployed
      .includes(:project)
      .includes(:testing_notes => :user)
      .includes(:releases)
      .includes(:commits) # so we can present committers
      .includes(:released_commits)
      .order("projects.name ASC")
  end
  
  def as_json
    tickets = ActiveRecord::Base.benchmark "\e[33m[testing_report_ticket_presenter] Load objects\e[0m" do
      @tickets.load
    end
    ActiveRecord::Base.benchmark "\e[33m[testing_report_ticket_presenter] Prepare JSON\e[0m" do
      tickets.map do |ticket|
        project = ticket.project
        { # generic
          id: ticket.id,
          projectId: project.id,
          projectSlug: project.slug,
          projectTitle: project.name,
          projectColor: project.color,
          ticketSystem: project.ticket_tracker_name,
          ticketUrl: ticket.ticket_tracker_ticket_url,
          number: ticket.number,
          summary: ticket.summary,
          type: ticket.type.to_s.downcase.dasherize,
          tags: ticket.tags.map(&:to_h),
        
          committers: ticket.committers(&:to_h),
          deployment: ticket.deployment,
          description: mdown(ticket.description),
        
          # specific to TestingReport
          priority: ticket.priority,
          verdictsByTester: ticket.verdicts_by_tester_index,
          dueDate: ticket.due_date,
          minPassingVerdicts: ticket.min_passing_verdicts,
          testingNotes: TestingNotePresenter.new(ticket.testing_notes).as_json,
          commits: CommitPresenter.new(ticket.released_commits).as_json,
          releases: ReleasePresenter.new(ticket.releases).as_json,
          lastReleaseAt: ticket.last_release_at }
      end
    end
  end
  
end
