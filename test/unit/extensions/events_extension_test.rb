require "test_helper"

class EventsExtensionTest < ActiveSupport::TestCase


  context "Houston.events" do
    should "be an instance of Houston::Events" do
      assert_kind_of Houston::Extensions::Events, Houston.events
    end
  end

  context "Houston.events[]" do
    should "return an instance of Houston::Extensions::Event for a registered static event" do
      assert_kind_of Houston::Extensions::Event, Houston.events["authorization:grant"]
    end

    should "return an instance of Houston::Extensions::Event for a registered dynamic event" do
      assert_kind_of Houston::Extensions::Event, Houston.events["daemon:anything:start"]
    end

    should "return nil for an unregistered event" do
      assert_nil Houston.events["anything"]
    end
  end


private

  def events
    @events ||= Houston::Extensions::Events.new
  end

end
