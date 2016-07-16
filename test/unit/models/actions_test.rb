require "test_helper"

class ActionsTest < ActiveSupport::TestCase

  def setup
    actions.define("test-action") { }
    Action.delete_all
  end


  context "Actions#define" do
    should "allow you to define the params an action requires" do
      action = actions.redefine("test-action", %w{param1 param2}) { }
      assert_equal "test-action", action.name
      assert_equal %w{param1 param2}, action.required_params
    end
  end


  context "Actions#run" do
    should "raise if called with an argument that isn't a Hash" do
      assert_raises ArgumentError do
        run! 5
      end
    end

    should "raise if any required params are absent" do
      actions.redefine("test-action", %w{param1 param2}) { }
      assert_raises Houston::Observer::MissingParamError do
        run! param1: 1
      end
    end

    should "allow unrequired params to be passed" do
      actions.redefine("test-action", %w{param1}) { }
      refute_raises Houston::Observer::MissingParamError do
        run! param1: 1, param2: 2
      end

      assert_equal({param1: 1, param2: 2}, Action.last.params)
    end

    # We require that all params be serializable so that (1) actions can
    # be recorded with all their state (and retried) and (2) the actions
    # system can be "outsourced" to a background job system like Sidekiq
    # if need be.
    should "raise if any required param is unserializable" do
      actions.redefine("test-action", %w{param1}) { }
      unserializable_object = Class.new.new
      assert_raises Houston::Serializer::UnserializableError do
        run! param1: unserializable_object
      end
    end

    should "record every invocation of the action" do
      assert_difference "Action.count", +1 do
        run!
      end
    end

    should "record any exception raised by the action" do
      actions.redefine("test-action") { raise "hell" }
      run!
      refute Action.last.succeeded?
      error = Action.last.error
      assert_kind_of Error, error
      assert_equal "hell", error.message
    end

    should "record how an action was triggered" do
      run!
      assert_equal "manual", Action.first.trigger

      run!({}, trigger: "at(5:00pm)")
      assert_equal "at(5:00pm)", Action.first.trigger
    end

    should "record the params with which an action was triggered" do
      run!
      assert_equal({}, Action.first.params)

      actions.redefine("test-action", [:example]) { }
      run! example: 5
      assert_equal({example: 5}, Action.first.params)
    end

    should "invoke actions in the context of their params" do
      actions.redefine("test-action") do
        assert respond_to?(:example)
        assert_equal 5, example
      end
      run! example: 5
    end
  end


private

  def actions
    @actions ||= Houston::Actions.new
  end

  def run!(params={}, options={})
    actions.run "test-action", params, options.merge(async: false)
  end

end
