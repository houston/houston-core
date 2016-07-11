require "test_helper"

class ConfigurationTest < ActiveSupport::TestCase


  context "#action" do
    should "define a new action" do
      config.action("test-action") { }
      assert config.actions.exists?("test-action")
    end

    should "raise if a block isn't given" do
      assert_raises ArgumentError do
        config.action("test-action")
      end
    end

    should "raise if the action has already been defined" do
      config.action("test-action") { }
      assert_raises ArgumentError do
        config.action("test-action") { }
      end
    end
  end


  context "#every" do
    should "define an action and a timer that triggers it when you pass two arguments" do
      config.every("10m", "test-action") { }
      assert config.actions.exists?("test-action")
    end

    should "define an action and a timer that triggers it when you pass a hash" do
      config.every("10m" => "test-action") { }
      assert config.actions.exists?("test-action")
    end
  end



private

  def config
    @config ||= Houston::Configuration.new
  end

end
