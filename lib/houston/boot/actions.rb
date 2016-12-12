module Houston
  class Actions
    class ExecutionContext < ReadonlyHash
    end


    def initialize
      @actions = Concurrent::Hash.new
    end


    def names
      actions.keys
    end

    def count
      actions.count
    end

    def exists?(name)
      actions.key?(name)
    end

    def [](name)
      actions[name]
    end

    def to_a
      actions.values
    end

    def define(name, required_params=[], &block)
      raise ArgumentError, "#{name.inspect} is already defined" if exists?(name)
      redefine(name, required_params, &block)
    end

    def redefine(name, required_params=[], &block)
      raise ArgumentError, "A block is required to define an action" unless block_given?
      actions[name] = Action.new(name, required_params, block)
    end

    def undefine(name)
      raise ArgumentError, "#{name.inspect} is not defined" unless exists?(name)
      actions.delete name
    end


    def run(name, params={}, options={})
      raise ArgumentError, "#{name.inspect} is not defined" unless exists?(name)
      action = actions.fetch(name)

      unless params.is_a?(Hash)
        raise ArgumentError, "params must be a Hash" unless params.respond_to?(:to_h)
        params = params.to_h
      end

      assert_required_params! action, params
      assert_serializable! params

      Houston.async(options.fetch(:async, true)) do
        action.send :run!, params, options
      end
    end


  private
    attr_reader :actions


    def assert_required_params!(action, params)
      action.assert_required_params! params.keys.map(&:to_s)
    end

    def assert_serializable!(params)
      Houston::Serializer.new.assert_serializable!(params)
    end


    class Action < Struct.new(:name, :required_params, :block)
      def initialize(name, required_params, block)
        super name, required_params.map(&:to_s), block
      end

      def assert_required_params!(params)
        missing_params = required_params - params
        if missing_params.any?
          raise Houston::Observer::MissingParamError, "#{missing_params.first.inspect} is a required param of the action #{name.inspect}"
        end
      end

    private

      def run!(params, options={})
        params = ExecutionContext.new(params)
        trigger = options.fetch(:trigger, "manual")

        ::Action.record name, params, trigger do
          Rails.logger.info "\e[34m[#{trigger} => #{name}] Running job\e[0m"
          params.instance_eval(&block)
        end
      end
    end


  end
end
