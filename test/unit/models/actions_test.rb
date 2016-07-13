require "test_helper"

class ActionsTest < ActiveSupport::TestCase

  def setup
    actions.define("test-action") { }
  end


  context "Actions#run" do
    should "record every invocation of the action" do
      assert_difference "Action.count", +1 do
        run!
      end
    end

    should "record any exception raised by the action" do
      actions.redefine("test-action") { raise "hell" }
      run!
      refute Action.last.succeeded?
      error = Action.last.error
      assert_kind_of Error, error
      assert_equal "hell", error.message
    end

    should "record how an action was triggered" do
      run!
      assert_equal "manual", Action.first.trigger

      run!({}, trigger: "at(5:00pm)")
      assert_equal "at(5:00pm)", Action.first.trigger
    end

    should "record the params with which an action was triggered" do
      run!
      assert_equal({}, Action.first.params)

      run! example: 5
      assert_equal({example: 5}, Action.first.params)
    end
  end


private

  def actions
    @actions ||= Houston::Actions.new
  end

  def run!(params={}, options={})
    actions.run "test-action", params, options.merge(async: false)
  end

end
