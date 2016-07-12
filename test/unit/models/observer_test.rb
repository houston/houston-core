require "test_helper"

class ObserverTest < ActiveSupport::TestCase


  context "Houston.observer.once" do
    should "trigger a callback and then unregister it" do
      calls = 0
      Houston.observer.once("test") { calls += 1 }
      Houston.observer.fire "test"
      Houston.observer.fire "test"
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

    should "invoke callbacks with {} if called with no arguments" do
      callback_args = :not_called
      Houston.observer.on("test") { |*args| callback_args = args }
      Houston.observer.fire "test"
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
