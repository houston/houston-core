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
      verdictsByTester: verdicts_by_tester_index(ticket),
      dueDate: ticket.due_date,
      minPassingVerdicts: ticket.min_passing_verdicts,
      testingNotes: TestingNotePresenter.new(ticket.testing_notes).as_json,
      commits: CommitPresenter.new(ticket.released_commits).as_json,
      releases: ReleasePresenter.new(ticket.releases).as_json,
      lastReleaseAt: ticket.last_release_at)
  end
  
private
  
  def verdicts_by_tester_index(ticket)
    verdicts = verdicts_by_tester(ticket)
    ticket.testers.each_with_index.each_with_object({}) { |(tester, i), response| response[i + 1] = verdicts[tester.id] if verdicts.key?(tester.id) }
  end
  
  def verdicts_by_tester(ticket)
    notes = ticket.testing_notes_since_last_release
    return {} if notes.empty?
    
    verdicts_by_tester = Hash[ticket.testers.map(&:id).zip([nil])]
    notes.each do |note|
      tester_id = note.user_id
      next unless verdicts_by_tester.key?(tester_id) # not was not by a tester
      
      if note.fail?
        verdicts_by_tester[tester_id] = "failing"
      elsif note.pass?
        verdicts_by_tester[tester_id] ||= "passing"
      end
    end
    verdicts_by_tester
  end
  
end
