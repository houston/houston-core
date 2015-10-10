require "test_helper"

class SprintTaskPresenterTest < ActiveSupport::TestCase
  attr_reader :sprint, :task, :user

  setup do
    @sprint = Sprint.create!(end_date: Date.new(2014, 9, 5))
  end


  context "When a task is completed" do
    context "before the end of the Sprint, it" do
      should "present the task as completed" do
        task = create(:task, completed_at: Time.zone.local(2014, 9, 5, 20, 30))
        assert present(task)[:completed]
      end
    end

    context "after the end of the Sprint, it" do
      should "not present the task as completed" do
        task = create(:task, completed_at: Time.new(2014, 9, 6, 4, 30))
        refute present(task)[:completed]
      end
    end
  end


  context "When a task is checked out in a sprint, it" do
    setup do
      @task = create(:task, completed_at: Time.new(2014, 9, 6, 4, 30))
      sprint.tasks.add task
      @user = User.first
      task.check_out! sprint, user
    end

    should "be presented as checked out for that sprint" do
      attrs = { id: user.id, email: user.email, firstName: user.first_name }
      assert_equal attrs, present(task)[:checkedOutBy],
        "Expected the user who checked out the task to be presented"
    end

    should "not be presented as checked out for another sprint" do
      other_sprint = Sprint.create!
      other_sprint.tasks.add task
      refute present(task, sprint: other_sprint)[:checkedOutBy],
        "Expected no one to have checked out the task yet in the new sprint"
    end
  end


private

  def present(task, sprint: @sprint)
    SprintTaskPresenter.new(sprint, task).as_json
  end

end
