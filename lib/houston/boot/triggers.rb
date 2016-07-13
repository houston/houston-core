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

    def on(event, action)
      push :on, event, action
    end

  private
    attr_reader :config

    def push(method_name, value, action)
      super Trigger.new(method_name, value, action)
      block = Proc.new { |params={}| run(method_name, value, action, params) }
      case method_name
      when :at then config.timer.at(value, &block)
      when :every then config.timer.every(value, &block)
      when :on then config.observer.on(value, &block)
      else raise NotImplementedError, "Unrecognized method name: #{method_name.inspect}"
      end
    end

    def run(method_name, value, action, params)
      Houston.actions.run action, params, trigger: "#{method_name}(#{value})"
    end

    Trigger = Struct.new(:method_name, :value, :action)

  end
end
