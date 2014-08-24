require "test_helper"


class TaskTest < ActiveSupport::TestCase
  attr_reader :task1, :task2
  
  
  
  context "When a task is created, it" do
    should "be assigned the next sequential number for its ticket" do
      task1 = a_ticket.tasks.create!(description: "New Step 1")
      task2 = a_ticket.tasks.create!(description: "Step 2")
      assert_equal [1, 2], [task1.number, task2.number],
        "Expected the tasks to have been assigned the correct numbers"
    end
    
    should "require description to be supplied" do
      task = a_ticket.tasks.build
      refute task.valid?, "Expected task to be invalid: it has no description and it's not the default task"
      assert_match /can't be blank/, task.errors.full_messages.join
    end
  end
  
  
  
  should "represent its number as a letter" do
    tests = {1 => "a", 3 => "c", 26 => "z", 27 => "aa", 28 => "ab", 53 => "ba", 1151 => "arg"}
    expectations = tests.values
    results = tests.keys.map { |number| Task.new(number: number).letter }
    assert_equal expectations, results, "Expected Tasks numbered #{tests.keys.join(", ")} to be lettered #{tests.values.join(", ")}"
  end
  
  should "be able to interpret letters as numbers" do
    tests = {1 => "a", 3 => "c", 26 => "z", 27 => "aa", 28 => "ab", 53 => "ba", 1151 => "arg"}
    expectations = tests.keys
    results = tests.values.map { |letter| Task.send(:to_number, letter) }
    assert_equal expectations, results, "Expected Tasks lettered #{tests.values.join(", ")} to map to the numbers #{tests.keys.join(", ")}"
  end
  
  should "not allow you to change its number, once assigned" do
    task = a_ticket.tasks.first
    assert_no_difference "task.number" do
      task.update_attributes(number: 6)
      task.reload
    end
  end
  
  
  
  context "Given a ticket" do
    context "with the default task, it" do
      should "replace the default task when I add a new task" do
        task = a_ticket.tasks.create!(description: "I replaced the default task")
        assert_equal 1, a_ticket.tasks.count, "Expected there to only be one task"
        assert_equal 1, task.number, "Expected the new task to be the new #1 task"
      end
      
      should "not allow deleting its only task" do
        ticket = a_ticket
        assert_no_difference "Task.count", "Expected to be prevented from deleting a ticket's only task" do
          ticket.tasks.first.destroy
        end
      end
    end
    
    
    context "with more than one task," do
      setup do
        @task1 = a_ticket.tasks.create!(description: "Another task") # replaces the default task -> a
        @task2 = a_ticket.tasks.create!(description: "Another dollar") # a second task -> b
      end
      
      should "be able to look up its tasks by number" do
        assert_equal task1, a_ticket.tasks.numbered(1).first
      end
      
      should "be able to look up its tasks by letter" do
        assert_equal task2, a_ticket.tasks.lettered("b").first
      end
      
      should "be able to delete an uncompleted task" do
        assert_difference "Task.count", -1, "Expected to be able to delete an uncompleted task" do
          task1.destroy
        end
      end
    end
  end
  
  
  
  context "When a task is committed, it" do
    should "not be marked completed" do
      task = a_ticket.tasks.create!(description: "New Step 1")
      stub(task.project).category.returns "Products"
      time = Time.now
      task.committed! Struct.new(:authored_at).new(time)
      assert_equal nil, task.completed_at
    end
  end
  
  context "When a task is released, it" do
    should "also be marked completed" do
      task = a_ticket.tasks.create!(description: "New Step 1")
      stub(task.project).category.returns "Products"
      time = Time.now
      task.send :cache_release_attributes, Struct.new(:created_at).new(time)
      assert_equal time, task.completed_at
    end
  end
  
  context "When a task for a Library is committed, it" do
    should "also be marked completed" do
      task = a_ticket.tasks.create!(description: "New Step 1")
      stub(task.project).category.returns "Libraries"
      time = Time.now
      task.committed! Struct.new(:authored_at).new(time)
      assert_equal time, task.completed_at
    end
  end
  
  
  
private
  
  def a_ticket
    @a_ticket ||= create(:ticket)
  end
  
end
