class GithubPostReceiveEvent
  attr_reader :params

  def self.process!(params)
    self.new(params).process!
  end

  def initialize(params)
    @params = params
  end

  # https://developer.github.com/v3/activity/events/types/#pushevent
  def process!
    Rails.logger.info "\e[34m[github] Processing Post-Receive Event\e[0m"
  end

end
