require "github/event"

module Github
  class CommentEvent < Event
    attr_reader :action, :comment, :project, :user

    class << self
      attr_accessor :type
    end

    delegate :type, to: "self.class"

    # https://developer.github.com/v3/activity/events/types/#commitcommentevent
    # https://developer.github.com/v3/activity/events/types/#issuecommentevent
    # https://developer.github.com/v3/activity/events/types/#pullrequestreviewcommentevent
    def initialize(payload)
      super
      @comment = payload.fetch "comment"
      @action = ACTION_MAP.fetch(payload.fetch "action", "created")
      comment["project"] = Project.find_by_slug payload["repository"]["name"]
    end

    def process!
      Houston.observer.fire "github:comment:#{action}", comment: comment
      Houston.observer.fire "github:comment:#{type}:#{action}", comment: comment
    end

    ACTION_MAP = {
      "created" => "create",
      "edited" => "update",
      "deleted" => "delete"
    }.freeze

  end
end
