require "test_helper"

class SprintsControllerTest < ActionController::TestCase
  include Devise::TestHelpers

  attr_reader :sprint

  setup do
    sign_in create(:developer)
    @sprint = Sprint.create!
  end


  context "#add_task" do
    should "add the given task to the sprint" do
      task = create(:task, effort: 5)
      assert_difference "sprint.tasks.count", +1 do
        post :add_task, id: sprint.id, task_id: task.id
        assert_response :ok
      end
    end

    should "not add the task if the sprint is completed" do
      task = create(:task, effort: 5)
      Timecop.freeze 1.week.from_now do
        post :add_task, id: sprint.id, task_id: task.id
        assert_response :unprocessable_entity
      end
    end
  end


  context "#remove_task" do
    should "remove the given task from the sprint" do
      task = create(:task)
      sprint.tasks.add task
      assert_difference "sprint.tasks.count", -1 do
        delete :remove_task, id: sprint.id, task_id: task.id
        assert_response :ok
      end
    end

    should "not remove the task if the sprint is completed" do
      task = create(:task)
      sprint.tasks.add task
      Timecop.freeze 1.week.from_now do
        delete :remove_task, id: sprint.id, task_id: task.id
        assert_response :unprocessable_entity
      end
    end
  end


end
