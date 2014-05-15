require "test_helper"


class TaskTest < ActiveSupport::TestCase
  include RR::Adapters::TestUnit
  
  
  
  context "When a task is created, it" do
    should "be assigned the next sequential number for its ticket" do
      task2 = a_ticket.tasks.create!(description: "Step 2")
      task3 = a_ticket.tasks.create!(description: "Step 3")
      assert_equal [2, 3], [task2.number, task3.number],
        "Expected the tasks to have been assigned the correct numbers"
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
  
  
  
  context "Given a ticket," do
    should "be able to look up its tasks by number" do
      target_task = a_ticket.tasks.create!(description: "The task I'm going to look for")
      assert_equal target_task, a_ticket.tasks.numbered(2).first
    end
    
    should "be able to look up its tasks by letter" do
      target_task = a_ticket.tasks.create!(description: "The task I'm going to look for")
      assert_equal target_task, a_ticket.tasks.lettered("b").first
    end
    
    
    
    context "with more than one task," do
      setup do
        a_ticket.tasks.create!(description: "Another task, another dollar")
      end
      
      should "be able to delete an uncompleted task" do
        ticket = a_ticket
        assert_difference "Task.count", -1, "Expected to be able to delete an uncompleted task" do
          ticket.tasks.first.destroy
        end
      end
    end
    
    should "not be able to delete its only task" do
      ticket = a_ticket
      assert_no_difference "Task.count", "Expected to be prevented from deleting a ticket's only task" do
        ticket.tasks.first.destroy
      end
    end
  end
  
  
  
private
  
  def a_ticket
    @a_ticket ||= Ticket.create!(project: a_project, type: "Bug", number: 1, summary: "Test summary")
  end
  
  def a_project
    @a_project ||= Project.create!(name: "Test", slug: "test")
  end
  
end
