class ProblemPresenter
  include ActionView::Helpers::DateHelper
  include CommitHelper
  
  attr_reader :project, :problems
  
  def initialize(project, problems)
    @project = project
    @problems = problems
  end
  
  def as_json(*args)
    Houston.benchmark "[problem_presenter] Prepare JSON" do
      @problems.map(&method(:problem_to_json))
    end
  end
  
  def problem_to_json(problem)
    { id: problem.id,
      ticketId: problem.ticket.try(:id),
      ticketUrl: (@project.ticket_tracker.ticket_url(problem.ticket) if problem.ticket),
      ticketNumber: problem.ticket.try(:number),
      token: problem.err_ids.first,
      url: problem.url,
      message: problem.message,
      where: problem.where,
      noticesCount: problem.notices_count,
      
      firstNotice: present_notice(problem.first_notice_at, problem.first_notice_commit, problem.first_notice_environment),
      lastNotice:  present_notice( problem.last_notice_at,  problem.last_notice_commit,  problem.last_notice_environment) }
  end
  
  def present_notice(time, sha, environment_name)
    { at: time,
      ago: distance_of_time_in_words(time, Time.now).gsub("about ", "") + " ago",
      commit: (format_sha(sha) unless sha.blank?),
      commitUrl: (project.repo.commit_url(sha) if project.repo.respond_to?(:commit_url)),
      release: present_release(sha, environment_name) }
  end
  
  def present_release(sha, environment_name)
    release = @project.releases.where(["LOWER(environment_name) = ?", environment_name.downcase]).find_by_commit1(sha) if environment_name && !sha.blank?
    { url: "/projects/#{@project.slug}/environments/#{environment_name}/releases/#{release.id}",
      at: release.created_at.strftime("%b %d") } if release
  end
  
end
