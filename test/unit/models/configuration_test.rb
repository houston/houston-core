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

    should "define an action with a made-up name (for now) when you don't specify an action" do
      action = nil
      assert_difference ["config.triggers.count", "config.actions.count"], +1 do
        action = config.every("10m") { }
      end
      assert_match /10m:[a-f0-9]{8,}/, action.name
    end

    should "define a timer for an existing action" do
      assert_difference "config.triggers.count", +1 do
        config.action("test-action") { }
        config.every "10m" => "test-action"
      end
    end

    should "raise if the action requires any params" do
      config.action("test-action", ["required_param"]) { }
      assert_raises Houston::Observer::MissingParamError do
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

    should "define the action to require the params passed by the event" do
      action = config.on("hooks:example", "test-action") { }
      assert_equal %w{params}, action.required_params
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

    should "raise if the event doesn't supply the action's required params" do
      config.action("test-action", ["required_param"]) { }
      assert_raises Houston::Observer::MissingParamError do
        config.on "hooks:example" => "test-action"
      end
    end
  end


private

  def config
    @config ||= Houston::Configuration.new
  end

end
