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

      # Ensure that we have a record of this open pull request
      # action: labeled, unlabeled, opened, closed, reopened, or synchronized
      pr = PullRequest.upsert! pull_request, as: actor

      # The Pull Request may be invalid if it isn't for a
      # project that exists in Houston.
      return unless pr && pr.persisted?

      if action == "labeled" || action == "unlabeled"
        label = payload["label"].to_h.stringify_keys.pick("name", "color")
        new_labels = pr.json_labels.reject { |l| l["name"] == label["name"] }
        new_labels << label if action == "labeled"
        replace_labels! pr.id, new_labels, as: actor
      end
    end

    def replace_labels!(id, new_labels, as: nil)
      PullRequest.transaction do
        pull_request = PullRequest.lock.find id
        pull_request.update_attributes! json_labels: new_labels, actor: actor
      end
    end

  end
end
