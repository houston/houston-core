require "test_helper"

class PersistentTriggerTest < ActiveSupport::TestCase


  context ".every" do
    should "define a new trigger" do
      trigger = PersistentTrigger.every("day at 2:30pm", "test-action", example: 5)
      assert_equal :every, trigger.type
      assert_equal "day at 2:30pm", trigger.value
      assert_equal "test-action", trigger.action
      assert_equal({example: 5}, trigger.params)
    end
  end


  context "Validations:" do
    should "require the action to exist" do
      trigger = PersistentTrigger.new(action: "undefined-action").tap(&:validate)
      assert_match /is not defined/, trigger.errors[:action].join
    end

    should "require the type to be one of :at, :every, or :on" do
      trigger = PersistentTrigger.new

      trigger.type = :every
      refute trigger.tap(&:validate).errors[:type].any?

      trigger.type = :on
      refute trigger.tap(&:validate).errors[:type].any?

      trigger.type = :nope
      assert trigger.tap(&:validate).errors[:type].any?
    end
  end


  context "#save!" do
    setup do
      @user = users(:boblail)
      Houston.config.actions.define("test-action") { }
    end

    teardown do
      Houston.config.actions.undefine("test-action")
    end

    should "add the trigger to the database" do
      assert_difference "PersistentTrigger.count", +1 do
        @user.triggers.every("day at 1:30pm", "test-action", example: 5).save!
      end
    end

    should "register the trigger" do
      assert_difference "Houston.config.triggers.count", +1 do
        @user.triggers.every("day at 2:30pm", "test-action", example: 5).save!
      end
    end
  end


  context "#destroy" do
    setup do
      @user = users(:boblail)
      Houston.config.actions.define("test-action") { }
      @trigger = @user.triggers.every("day at 2:30pm", "test-action", example: 5).tap(&:save!)
    end

    teardown do
      Houston.config.actions.undefine("test-action")
    end

    should "remove the trigger from the database" do
      assert_difference "PersistentTrigger.count", -1 do
        @trigger.destroy
      end
    end

    should "unregister the trigger" do
      assert_difference "Houston.config.triggers.count", -1 do
        @trigger.destroy
      end
    end
  end


  context ".load_all" do
    setup do
      PersistentTrigger.all.insert({
        PersistentTrigger.column_for_attribute(:user_id) => users(:boblail).id,
        PersistentTrigger.column_for_attribute(:type) => "every",
        PersistentTrigger.column_for_attribute(:value) => "day at 9:00am",
        PersistentTrigger.column_for_attribute(:action) => "test-action",
        PersistentTrigger.column_for_attribute(:params) => {example: 5}
      })
    end

    teardown do
      Houston.config.triggers.clear
    end

    should "load all persisted triggers and register them" do
    assert_equal 1, PersistentTrigger.count
      assert_difference "Houston.config.triggers.count", +1 do
        PersistentTrigger.load_all
      end
    end

    should "be idempotent" do
      PersistentTrigger.load_all
      assert_no_difference "Houston.config.triggers.count" do
        PersistentTrigger.load_all
      end
    end
  end


end
