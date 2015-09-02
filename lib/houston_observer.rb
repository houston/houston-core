require "thread_safe"

module Houston
  class Observer

    def initialize
      @async = true
      clear!
    end

    attr_accessor :async

    def on(event, &block)
      observers_of(event).push(block)
      nil
    end

    def once(event, &block)
      wrapped_block = Proc.new do |*args|
        block.call(*args)
        observers_of(event).delete wrapped_block
      end
      on(event, &wrapped_block)
    end

    def observed?(event)
      observers_of(event).any?
    end

    def fire(event, *args)
      invoker = async ? method(:invoke_callback_async) : method(:invoke_callback)
      observers_of(event).each do |block|
        invoker.call(event, block, *args)
      end
      nil
    end

    def clear!
      @observers = {}
    end

  private

    def invoke_callback_async(event, block, *args)
      Thread.new do
        begin
          invoke_callback(event, block, *args)
        ensure
          ActiveRecord::Base.clear_active_connections!
          Rails.logger.flush # http://stackoverflow.com/a/3516003/731300
        end
      end
    end

    def invoke_callback(event, block, *args)
      block.call(*args)
    rescue Exception # rescues StandardError by default; but we want to rescue and report all errors
      $!.additional_information[:event] = event
      Houston.report_exception($!)
    end

    def observers_of(event)
      observers[event] ||= ThreadSafe::Array.new
    end

    attr_reader :observers

  end
end
