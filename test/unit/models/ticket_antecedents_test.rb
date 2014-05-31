require 'test_helper'

class TicketAntecedentsTest < ActiveSupport::TestCase
  attr_reader :antecedent
  
  setup do
    @antecedent = TicketAntecedent.new(nil, "Gollum", 45)
  end
  
  
  
  context "#release!" do
    should "raise the release event" do
      assert_triggered "antecedent:gollum:released" do
        antecedent.release!
      end
    end
  end
  
  context "#resolve!" do
    should "raise the release event" do
      assert_triggered "antecedent:gollum:resolved" do
        antecedent.resolve!
      end
    end
  end
  
  context "#close!" do
    should "raise the release event" do
      assert_triggered "antecedent:gollum:closed" do
        antecedent.close!
      end
    end
  end
  
  
  
end
