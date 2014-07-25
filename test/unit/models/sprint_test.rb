require "test_helper"

class SprintTest < ActiveSupport::TestCase
  attr_reader :sprint, :task, :old_sprint
  
  context "When a task is put into a sprint, it" do
    setup do
      @old_sprint = Sprint.create!(end_date: 1.week.ago)
      @sprint = Sprint.create!
      @task = create(:task)
    end
    
    should "be associated with the sprint" do
      sprint.tasks.add task
      assert_equal [sprint], task.sprints.to_a
    end
    
    should "not be added again if it's already there" do
      sprint.tasks.add task
      assert_nothing_raised do
        assert_no_difference "SprintTask.count" do
          sprint.tasks.add task
        end
      end
    end
    
    should "still be associated with any previous sprints it was in" do
      old_sprint.tasks.add task
      sprint.tasks.add task
      assert_equal [old_sprint, sprint], task.sprints.to_a
    end
  end
  
end
