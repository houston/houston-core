class GithubPullRequestEvent
  attr_reader :params

  def self.process!(params)
    self.new(params).process!
  end

  def initialize(params)
    @params = params
  end

  # https://developer.github.com/v3/activity/events/types/#pullrequestevent
  def process!
    Rails.logger.info "\e[34m[github] Processing Pull Request Event\e[0m"
  end

end
