require "delegate"

module Houston
  class DuplicateTriggerError < ArgumentError; end


  class Triggers < SimpleDelegator
    attr_reader :config

    def initialize(config)
      @config = config
      super Concurrent::Array.new
    end


    def every(value, action, params={})
      push build(:every, value, action, params)
    end

    def on(event, action, params={})
      push build(:on, event, action, params)
    end

    def build(method_name, value, action, params, persistent_trigger_id: nil)
      Trigger.new(self, method_name, value, action, params, persistent_trigger_id)
    end

    def push(trigger)
      raise DuplicateTriggerError, "That exact trigger has already been defined" if member?(trigger)
      super trigger
      trigger.register!
      trigger
    end

    def delete(trigger)
      i = find_index(trigger)
      return unless i
      trigger = self[i]
      trigger.unregister!
      delete_at i
    end

  end


  class Trigger < Struct.new(:method_name, :value, :action, :params, :persistent_trigger_id)

    def initialize(triggers, *args)
      @triggers = triggers
      @callback = method(:call).to_proc
      super *args
    end

    def register!
      case method_name
      when :every then config.timer.every(value, &callback)
      when :on then config.observer.on(value, &callback)
      else raise NotImplementedError, "Unrecognized method name: #{method_name.inspect}"
      end
    end

    def unregister!
      case method_name
      when :every then config.timer.stop(value, callback)
      when :on then config.observer.off(value, &callback)
      else raise NotImplementedError, "Unrecognized method name: #{method_name.inspect}"
      end
    end

    def call(params={})
      Rails.logger.info "\e[34m[#{to_s} => #{action}]\e[0m"
      config.actions.run action, self.params.merge(params.to_h), trigger: to_s
    end

    def to_s
      "#{method_name}(#{value})"
    end

  private
    attr_reader :triggers, :callback

    def config
      triggers.config
    end

  end
end
