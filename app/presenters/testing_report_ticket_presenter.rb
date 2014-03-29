class TestingReportTicketPresenter < TicketPresenter
  include MarkdownHelper
  
  def initialize(tickets)
    super tickets
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
  
  def ticket_to_json(ticket)
    super.merge(
      committers: ticket.committers(&:to_h),
      deployment: ticket.deployment,
      description: mdown(ticket.description),
      priority: ticket.priority,
      verdictsByTester: ticket.verdicts_by_tester_index,
      dueDate: ticket.due_date,
      minPassingVerdicts: ticket.min_passing_verdicts,
      testingNotes: TestingNotePresenter.new(ticket.testing_notes).as_json,
      commits: CommitPresenter.new(ticket.released_commits).as_json,
      releases: ReleasePresenter.new(ticket.releases).as_json,
      lastReleaseAt: ticket.last_release_at)
  end
  
end
