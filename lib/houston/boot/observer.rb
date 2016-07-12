require "thread_safe"

module Houston
  class Observer
    attr_accessor :async

    def initialize
      @async = true
      clear!
    end

    def on(event, options={}, &block)
      observers_of(event).push Callback.new(event, options, block)
      nil
    end

    def once(event, options={}, &block)
      wrapped_block = Proc.new do |*args|
        block.call(*args)
        observers_of(event).delete wrapped_block
      end
      on(event, options, &wrapped_block)
    end

    def observed?(event)
      observers_of(event).any?
    end

    def fire(event, params={})
      unless params.is_a?(Hash)
        raise ArgumentError, "params must be a Hash" unless params.respond_to?(:to_h)
        params = params.to_h
      end
      params = ReadonlyHash.new(params)

      observers_of(event).each do |callback|
        callback.call params
      end
      nil
    end

    def clear!
      @observers = {}
    end

  private
    attr_reader :observers

    def observers_of(event)
      observers[event] ||= ThreadSafe::Array.new
    end



    class Callback
      attr_reader :event

      def initialize(event, options, block)
        @event = event
        @invoke_async = options.fetch(:async, nil)
        @raise_exceptions = options.fetch(:raise, false)
        @block = block
      end

      def invoke_async?
        return @invoke_async unless @invoke_async.nil?
        Houston.observer.async
      end

      def raise_exceptions?
        @raise_exceptions
      end

      def call(params)
        Houston.async(invoke_async?) do
          begin
            @block.call(params)

          rescue Exception # rescues StandardError by default; but we want to rescue and report all errors
            raise if raise_exceptions?

            $!.additional_information[:event] = event
            $!.additional_information[:async] = invoke_async?
            $!.additional_information[:raise_exceptions] = raise_exceptions?
            Houston.report_exception($!)
          end
        end
      end

    end

  end



  class ReadonlyHash

    def initialize(hash)
      @hash = hash.symbolize_keys
      @hash.keys.each do |key|
        define_singleton_method(key) { @hash[key] }
      end
    end

    def [](key)
      @hash[key.to_sym]
    end

    def count
      @hash.count
    end

    def to_h
      @hash.dup
    end

  end
end
