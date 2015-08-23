require "github/event"

module Github
  class CommentEvent < Event
    attr_reader :comment, :project, :user

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
      comment["project"] = Project.find_by_slug payload["repository"]["name"]
    end

    def process!
      Rails.logger.info "\e[34m[github] Processing Comment Event (type: #{type})\e[0m"
      Houston.observer.fire "github:comment", comment
      Houston.observer.fire "github:comment:#{type}", comment
    end

  end
end
