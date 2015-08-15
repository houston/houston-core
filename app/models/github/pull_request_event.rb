module Github
  class PullRequestEvent
    attr_reader :payload

    def self.process!(payload)
      self.new(payload).process!
    end

    def initialize(payload)
      @payload = payload
    end

    # https://developer.github.com/v3/activity/events/types/#pullrequestevent
    def process!
      Rails.logger.info "\e[34m[github] Processing Pull Request Event\e[0m"
    end

  end
end
