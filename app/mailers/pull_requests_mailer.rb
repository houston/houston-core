class PullRequestsMailer < ViewMailer
  
  def self.deliver_to!(*recipients)
    recipients.flatten.each do |email|
      user = User.find_by_email!(email)
      pull_requests(user).deliver!
    end
  end
  
  
  def pull_requests(user)
    @pull_requests_by_repo = Github::PullRequests.new(user).to_h
    mail({
      to: user.email,
      subject: "#{@pull_requests_by_repo.values.flatten.select(&:eligible?).length} pull requests",
      template: "pull_requests/index"
    })
    
  rescue Github::Unauthorized
    mail({
      to: user.email,
      subject: "Pull Requests",
      template: "pull_requests/need_access"
    })
  end
  
end
