require "test_helper"

Houston.register_events {{
  "test" => params("example").desc("For testing the observer"),
  "test0" => desc("For testing the observer, takes 0 params")
}}

class ObserverTest < ActiveSupport::TestCase


  context "Houston.observer.once" do
    should "trigger a callback and then unregister it" do
      calls = 0
      Houston.observer.once("test0") { calls += 1 }
      Houston.observer.fire "test0"
      Houston.observer.fire "test0"
      assert_equal 1, calls, "Expected the callback to be called only once"
    end
  end


  context "Houston.observer.fire" do
    should "raise if called with an argument that isn't a Hash" do
      assert_raises ArgumentError do
        Houston.observer.fire "test", 5
      end
    end

    should "raise if called with more than one argument" do
      assert_raises ArgumentError do
        Houston.observer.fire "test", {}, 5
      end
    end

    should "raise if the event isn't registered" do
      assert_raises Houston::Observer::UnregisteredEventError do
        Houston.observer.fire "test2"
      end
    end

    should "raise if the event is triggered without a registered param" do
      assert_raises Houston::Observer::MissingParamError do
        Houston.observer.fire "test", {}
      end
    end

    should "raise if the event is triggered with an unregistered param" do
      assert_raises Houston::Observer::UnregisteredParamError do
        Houston.observer.fire "test", {example: 5, counterexample: 1}
      end
    end

    # We require that all params be serializable so that (1) actions can
    # be recorded with all their state (and retried) and (2) the actions
    # system can be "outsourced" to a background job system like Sidekiq
    # if need be.
    should "raise if the event is triggered with an unserializable param" do
      unserializable_object = Class.new.new
      assert_raises Houston::Serializer::UnserializableError do
        Houston.observer.fire "test", {example: unserializable_object}
      end
    end

    should "invoke callbacks with {} if called with no arguments" do
      callback_args = :not_called
      Houston.observer.on("test0") { |*args| callback_args = args }
      Houston.observer.fire "test0"
      assert_equal 1, callback_args.length
      assert_equal [], callback_args[0].methods(false)
    end

    should "invoke callbacks with a copy of the params it was called with" do
      params = {example: 5}
      callback_params = :not_called
      Houston.observer.on("test") { |params| callback_params = params }
      Houston.observer.fire "test", params
      assert_equal params, callback_params.to_h
      refute_equal params.object_id, callback_params.to_h.object_id,
        "Expected the observer to be invoked with a copy of the params; not the actual params itself"
    end
  end


  context "callback params" do
    should "be retrievable by array-style access" do
      callback_params = :not_called
      Houston.observer.on("test") { |params| callback_params = params }
      Houston.observer.fire "test", example: 5
      assert_equal 5, callback_params[:example]
    end

    should "be retrievable by method-style access" do
      callback_params = :not_called
      Houston.observer.on("test") { |params| callback_params = params }
      Houston.observer.fire "test", example: 5
      assert_equal 5, callback_params.example
    end
  end


end
