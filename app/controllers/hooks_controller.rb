class HooksController < ApplicationController
  skip_before_filter :verify_authenticity_token

  # https://developer.github.com/webhooks/#events
  def github
    event = request.headers["X-GitHub-Event"]
    payload = params.except(:action, :controller)
    case event
    when "ping"
      Rails.logger.info "\e[32m[github] ping received\e[0m"
      head 200

    when "pull_request"
      Github::PullRequestEvent.process!(payload)
      head 200

    when "push"
      Github::PostReceiveEvent.process!(payload)
      head 200

    else
      Rails.logger.warn "\e[33m[github] Unrecognized event: #{event}\e[0m"
      head 404
    end
  end

end
