class TestingReportTicketPresenter < TicketPresenter
  include MarkdownHelper
  
  def initialize(tickets)
    super tickets
      .unclosed
      .fixed
      .includes(:project)
      .includes(:testing_notes => :user)
      .includes(:releases)
    @committers_by_ticket = Commit
      .joins("INNER JOIN commits_tickets ON commits_tickets.commit_id=commits.id")
      .where(["commits_tickets.ticket_id IN (?)", @tickets.pluck(:id)])
      .where(unreachable: false)
      .pluck("commits_tickets.ticket_id", :committer, :committer_email)
      .each_with_object({}) { |(ticket_id, committer_name, committer_email), map|
        (map[ticket_id] ||= Set.new) << TicketCommitter.new(committer_name, committer_email) }
    @released_commits_by_ticket = Commit
      .joins("INNER JOIN commits_tickets ON commits_tickets.commit_id=commits.id")
      .where(["commits_tickets.ticket_id IN (?)", @tickets.pluck(:id)])
      .reachable
      .released
      .select("commits.*, commits_tickets.ticket_id")
      .group_by(&:ticket_id)
  end
  
  def as_json(*args)
    super(*args).sort_by { |ticket| ticket[:projectTitle] }
  end
  
  def ticket_to_json(ticket)
    super.merge(
      committers: @committers_by_ticket.fetch(ticket.id, Set.new).map(&:to_h),
      deployment: ticket.deployment,
      description: mdown(ticket.description),
      priority: ticket.priority,
      verdictsByTester: verdicts_by_tester_index(ticket),
      dueDate: ticket.due_date,
      minPassingVerdicts: ticket.min_passing_verdicts,
      testingNotes: TestingNotePresenter.new(ticket.testing_notes).as_json,
      commits: CommitPresenter.new(@released_commits_by_ticket.fetch(ticket.id, [])).as_json,
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
