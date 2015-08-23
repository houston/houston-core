require "github/event"

module Github
  class Event
    attr_reader :payload

    def self.process!(payload)
      self.new(payload).process!
    end

    def initialize(payload)
      @payload = payload
    end

    def process!
      raise NotImplementedError
    end

  end
end
