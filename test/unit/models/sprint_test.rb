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


  context "Sprint#current" do
    should "return the current sprint" do
      sprint = Sprint.create!(end_date: Date.new(2014, 9, 5))
      Timecop.freeze Time.new(2014, 9, 5, 23, 0, 0) do
        assert_equal sprint.id, Sprint.current.try(:id), "Expected Sprint#current to find the sprint that ends this week"
      end
    end
  end

end
