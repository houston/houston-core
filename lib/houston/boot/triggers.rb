require "thread_safe"
require "delegate"

module Houston
  class Triggers < SimpleDelegator

    def initialize(config)
      @config = config
      super ThreadSafe::Array.new
    end

    def at(value, action)
      push :at, value, action
    end

    def every(value, action)
      push :every, value, action
    end

    def on(value, action)
      push :on, value, action
    end

  private
    attr_reader :config

    def push(method_name, value, action)
      super Trigger.new(method_name, value, action)
      case method_name
      when :at then config.timer.at(value, action)
      when :every then config.timer.every(value, action)
      end
    end

    Trigger = Struct.new(:method_name, :value, :action)
  end
end
