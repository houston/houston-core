module Github
  class PullRequestEvent
    attr_reader :action, :pull_request

    def self.process!(payload)
      self.new(payload).process!
    end

    # https://developer.github.com/v3/activity/events/types/#pullrequestevent
    def initialize(payload)
      @action = payload.fetch "action"
      @pull_request = payload.fetch "pull_request"
    end

    def process!
      Rails.logger.info "\e[34m[github] Processing Pull Request Event (action: #{action})\e[0m"
      if action == "closed"
        PullRequest.close! pull_request
      else
        PullRequest.upsert! pull_request
      end
    end

  end
end
