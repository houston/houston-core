require "test_helper"

class DeployTest < ActiveSupport::TestCase
  include RR::Adapters::TestUnit
  
  
  context "a new deploy" do
    should "strip trailing line breaks from a commit" do
      deploy = Deploy.new(commit: "edd44727c05c93b34737cb48873929fb5af69885\n")
      assert_equal "edd44727c05c93b34737cb48873929fb5af69885", deploy.commit
    end
  end
  
  
end
