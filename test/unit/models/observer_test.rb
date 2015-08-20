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


end
