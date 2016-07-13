require "github/event"

module Github
  class PostReceiveEvent < Event

    # https://developer.github.com/v3/activity/events/types/#pushevent
    def process!
      Rails.logger.info "\e[34m[github] Processing Post-Receive Event\e[0m"
      project = Project.find_by_slug! payload["repository"]["name"]
      Houston.observer.fire "hooks:project:post_receive", project: project, params: payload
    end

  end
end
