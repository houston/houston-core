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
      assert_difference "config.triggers.count", +1 do
        config.every("10m", "test-action") { }
        assert config.actions.exists?("test-action")
      end
    end

    should "define an action and a timer that triggers it when you pass a hash" do
      assert_difference "config.triggers.count", +1 do
        config.every("10m" => "test-action") { }
        assert config.actions.exists?("test-action")
      end
    end

    should "define a timer for an existing action" do
      assert_difference "config.triggers.count", +1 do
        config.action("test-action") { }
        config.every "10m" => "test-action"
      end
    end
  end


  context "#on" do
    should "define an action and an observer that triggers it when you pass two arguments" do
      assert_difference "config.triggers.count", +1 do
        config.on("hooks:example", "test-action") { }
        assert config.actions.exists?("test-action")
      end
    end

    should "define an action and an observer that triggers it when you pass a hash" do
      assert_difference "config.triggers.count", +1 do
        config.on("hooks:example" => "test-action") { }
        assert config.actions.exists?("test-action")
      end
    end

    should "define an observer for an existing action" do
      assert_difference "config.triggers.count", +1 do
        config.action("test-action") { }
        config.on "hooks:example" => "test-action"
      end
    end
  end


  context "Triggers" do
    should "invoke actions in the context of their params" do
      config.action("test-action") do
        assert respond_to?(:example)
        assert_equal 5, example
      end
      config.actions.run "test-action", {example: 5}, {async: false}
    end
  end


private

  def config
    @config ||= Houston::Configuration.new
  end

end
