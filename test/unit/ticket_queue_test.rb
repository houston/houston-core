require 'test_helper'

class TicketQueueTest < ActiveSupport::TestCase
  
  
  test "must be for a valid queue" do
    ticket = Ticket.new(project_id: 1, number: 1, summary: "Test summary")
    
    valid_queue = TicketQueue.new(ticket: ticket, queue: "in_testing")
    assert_equal true, valid_queue.valid?
    
    invalid_queue = TicketQueue.new(ticket: ticket, queue: "not_a_chance")
    assert_equal false, invalid_queue.valid?
  end
  
  
  test "deleting a queue (loaded via a ticket) sets its destroy_at property" do
    ticket = Ticket.create!(project_id: 1, number: 1, summary: "Test summary")
    TicketQueue.create!(ticket: ticket, queue: "in_testing")
    
    queue = Ticket.find(1).ticket_queue
    
    queue.destroy
    assert_not_nil queue.destroyed_at, "Expected destroyed_at to be set"
  end
  
  
end
