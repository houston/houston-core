module Github
  class PostReceiveEvent
    attr_reader :payload

    def self.process!(payload)
       self.new(payload).process!
    end

    def initialize(payload)
      @payload = payload
    end

    # https://developer.github.com/v3/activity/events/types/#pushevent
    def process!
      Rails.logger.info "\e[34m[github] Processing Post-Receive Event\e[0m"
    end

  end
end
