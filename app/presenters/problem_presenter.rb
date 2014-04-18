class ProblemPresenter
  include ActionView::Helpers::DateHelper
  
  def initialize(problems)
    @problems = OneOrMany.new(problems)
  end
  
  def as_json(*args)
    Houston.benchmark "[problem_presenter] Prepare JSON" do
      @problems.map(&method(:problem_to_json))
    end
  end
  
  def problem_to_json(problem)
    { ticketId: problem.ticket.try(:id),
      token: problem.err_ids.first,
      url: problem.url,
      message: problem.message,
      where: problem.where,
      lastNoticeAt: problem.last_notice_at,
      lastNoticeAgo: distance_of_time_in_words(problem.last_notice_at, Time.now),
      noticesCount: problem.notices_count }
  end
  
end
