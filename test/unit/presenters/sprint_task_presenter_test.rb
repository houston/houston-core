require "test_helper"

class SprintTaskPresenterTest < ActiveSupport::TestCase
  attr_reader :sprint
  
  setup do
    @sprint = Sprint.create!(end_date: Date.new(2014, 9, 5))
  end
  
  
  context "When a task is completed" do
    context "before the end of the Sprint, it" do
      should "present the task as completed" do
        task = create(:task, completed_at: Time.new(2014, 9, 5, 20, 30))
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
  
  
private
  
  def present(task)
    SprintTaskPresenter.new(sprint, task).as_json
  end
  
end
