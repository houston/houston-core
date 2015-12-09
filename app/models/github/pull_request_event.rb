require "github/event"

module Github
  class PullRequestEvent < Event
    attr_reader :action, :pull_request, :actor

    # https://developer.github.com/v3/activity/events/types/#pullrequestevent
    def initialize(payload)
      super
      @action = payload.fetch "action"
      @pull_request = payload.fetch "pull_request"
      @actor = payload.fetch("sender", {})["login"]
    end

    def process!
      Rails.logger.info "\e[34m[github] Processing Pull Request Event (action: #{action})\e[0m"

      # Ignore when pull requests are assigned
      if action == "assigned" || action == "unassigned"
        return
      end

      # Delete pull requests when they are closed
      if action == "closed"
        PullRequest.close! pull_request, as: actor
        return
      end

      # Ensure that we have a record of this open pull request
      # action: labeled, unlabeled, opened, reopened, or synchronized
      pr = PullRequest.upsert! pull_request, as: actor

      # The Pull Request may be invalid if it isn't for a
      # project that exists in Houston.
      return unless pr && pr.persisted?

      case action
      when "labeled" then pr.add_label! payload["label"], as: actor
      when "unlabeled" then pr.remove_label! payload["label"], as: actor
      end
    end

  end
end
