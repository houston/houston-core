require "github/comment_event"

module Github
  class IssueCommentEvent < CommentEvent

    def initialize(payload)
      super
      comment["issue"] = payload.fetch "issue"
    end

    def type
      @type ||= payload["issue"]["pull_request"] ? "pull" : "issue"
    end

  end
end
