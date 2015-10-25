require "test_helper"

class FixturesTest < ActiveSupport::TestCase

  context "The Test Suite" do
    should "load the fixtures defined in this engine" do
      assert Project["test"], "Expected to find the 'test' project"
    end
  end

end
