require "github/event"

module Github
  class PullRequestReviewEvent < Event
    attr_reader :review, :pull_request, :actor, :state

    # https://developer.github.com/v3/activity/events/types/#pullrequestreviewevent
    def initialize(payload)
      super
      @pull_request = payload.fetch "pull_request"
      @review = payload.fetch "review"
      @state = review.fetch("state")
      @actor = review.fetch("user", {})["login"]
    end

    def process!
      Rails.logger.info "\e[34m[github] Processing Pull Request Review Event\e[0m"

      # Ensure that we have a record of this open pull request
      pr = PullRequest.upsert! pull_request, as: actor

      # The Pull Request may be invalid if it isn't for a
      # project that exists in Houston.
      return unless pr && pr.persisted?

      Houston.observer.fire "github:pull:reviewed", pull_request: pr, review: review
      Houston.observer.fire "github:pull:reviewed:#{state}", pull_request: pr, review: review
    end

  end
end
