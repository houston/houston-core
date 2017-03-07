module Houston
  class Actions
    class UndefinedActionError < ArgumentError; end
    class ExecutionContext < ReadonlyHash; end

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

    def fetch(name)
      actions.fetch(name)
    rescue KeyError
      raise UndefinedActionError, "#{name.inspect} is not defined"
    end

    def to_a
      actions.values
    end

    def clear
      actions.clear
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
      action = fetch(name)

      unless params.is_a?(Hash)
        raise ArgumentError, "params must be a Hash" unless params.respond_to?(:to_h)
        params = params.to_h
      end

      assert_required_params! action, params
      assert_serializable! params

      Houston.async(options.fetch(:async, true)) do
        ::Action.run! name, params, options.fetch(:trigger, "manual")
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
        raise Houston::Observer::MissingParamError, "#{missing_params.first.inspect} is a required param of the action #{name.inspect}" if missing_params.any?
      end

      def execute(params)
        assert_required_params! params.keys.map(&:to_s)
        ExecutionContext.new(params).instance_eval(&block)
      end
    end

  end
end
