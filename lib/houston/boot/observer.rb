module Houston
  class Observer
    attr_accessor :async

    class UnregisteredEventError < ArgumentError; end
    class MissingParamError < ArgumentError; end
    class UnregisteredParamError < ArgumentError; end

    def initialize
      @async = true
      clear!
    end

    def on(event, options={}, &block)
      assert_registered! event
      observers_of(event).push Callback.new(self, event, options, block)
      nil
    end

    def once(event, options={}, &block)
      assert_registered! event
      observers_of(event).push CallbackOnce.new(self, event, options, block)
      nil
    end

    def off(callback)
      observers_of(callback.event).delete callback
      nil
    end

    def observed?(event)
      assert_registered! event
      observers_of(event).any?
    end

    def fire(event, params={})
      assert_registered! event

      unless params.is_a?(Hash)
        raise ArgumentError, "params must be a Hash" unless params.respond_to?(:to_h)
        params = params.to_h
      end

      assert_registered_params! event, params
      assert_serializable! params
      params = ReadonlyHash.new(params)

      observers_of(event).each do |callback|
        callback.call params
      end
      observers_of(:*).each do |callback|
        callback.call event, params
      end
      nil
    end

    def clear!
      @observers = {}
    end

  private
    attr_reader :observers

    def observers_of(event)
      observers[event] ||= Concurrent::Array.new
    end

    def assert_registered!(event_name)
      return if event_name == :*
      return if Houston.registered_event?(event_name)
      raise UnregisteredEventError, "#{event_name.inspect} is not a registered event"
    end

    def assert_registered_params!(event_name, params)
      event = Houston.get_registered_event(event_name)

      missing_params = event.params - params.keys.map(&:to_s)
      unregistered_params = params.keys.map(&:to_s) - event.params
      if missing_params.any?
        raise MissingParamError, "#{missing_params.first.inspect} is a required param of the event #{event_name.inspect}"
      end
      if unregistered_params.any?
        raise UnregisteredParamError, "#{unregistered_params.first.inspect} is a not a registered param of the event #{event_name.inspect}"
      end
    end

    def assert_serializable!(params)
      Houston::Serializer.new.assert_serializable!(params)
    end



    class Callback
      attr_reader :observer, :event

      def initialize(observer, event, options, block)
        @observer = observer
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

      def call(*args)
        Houston.async(invoke_async?) do
          begin
            @block.call(*args)

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

    class CallbackOnce < Callback
      def call(*args)
        observer.off self
        super
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
