class ProjectTDL < SimpleDelegator
  
  def self.for(projects, current_user)
    pull_requests_by_repo = current_user.developer? ? Github::PullRequests.new(current_user).to_h : {}
    projects.map do |project|
      self.new(project, pull_requests_by_repo.fetch(project.slug, []))
    end
  end
  
  def initialize(project, pull_requests)
    super(project)
    @unestimated_tickets = has_ticket_tracker? ? tickets.unresolved.able_to_estimate.unestimated.count : nil
    @unprioritized_tickets = has_ticket_tracker? ? tickets.unresolved.able_to_prioritize.unprioritized.count : nil
    testing_notes = TestingNote.for_tickets(tickets.unclosed.fixed.deployed)
    @failing_tickets = testing_notes.where(verdict: %w{fails badticket}).pluck(:ticket_id).uniq.count
    @pull_requests = pull_requests.empty? ? nil : pull_requests.count
  end
  
  attr_reader :unestimated_tickets,
              :unprioritized_tickets,
              :pull_requests,
              :failing_tickets
  
  def unreleased_commits
    return nil unless unreleased_commit_range
    repo.commits_between(*unreleased_commit_range).count rescue 0/0.0
  end
  
  def unreleased_commit_range
    return @unreleased_commit_range if defined?(@unreleased_commit_range)
    @unreleased_commit_range = begin
      production = releases.to_environment("Production").first
      staging = releases.to_environment("Staging").first
      staging && production && [production.commit1, staging.commit1]
    end
  end
  
  def score_options(arg)
    case arg
    when :unreleased_commits
      return {} unless unreleased_commits
      return {} unless repo.respond_to?(:commit_range_url)
      { href: repo.commit_range_url(*unreleased_commit_range) }
    when :unestimated_tickets
      return {} unless unestimated_tickets
       { href: "/scheduler/by_project/#{slug}#estimate-effort" }
    when :unprioritized_tickets
      return {} unless unprioritized_tickets
       { href: "/scheduler/by_project/#{slug}#sequence" }
    when :pull_requests
      return {} unless pull_requests
      { href: repo.pull_requests_url }
    when :failing_tickets
      { href: "/testing_report/#{slug}" }
    else
      {}
    end
  end
  
end
