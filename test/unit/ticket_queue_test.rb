require 'test_helper'

class TicketQueueTest < ActiveSupport::TestCase
  
  attr_reader :ticket
  
  setup do
    @ticket = Ticket.create!(project_id: 1, number: 1, summary: "Test summary", type: "Bug")
  end
  
  
  
  test "must be for a valid queue" do
    valid_queue = TicketQueue.new(ticket: ticket, queue: "unprioritized")
    assert valid_queue.valid?, "Expected 'unprioritized' to be a valid queue"
    
    invalid_queue = TicketQueue.new(ticket: ticket, queue: "not_a_chance")
    refute invalid_queue.valid?, "Expected 'not_a_chance' not to be a valid queue"
  end
  
  
  test "deleting a queue (loaded via a ticket) sets its destroy_at property" do
    TicketQueue.create!(ticket: ticket, queue: "unprioritized")
    
    queue = Ticket.find_by_number(1).ticket_queues.first
    
    queue.destroy
    assert_not_nil queue.destroyed_at, "Expected destroyed_at to be set"
  end
  
  
  test "#enter! should record the time a number of tickets entered a queue" do
    ticket2 = Ticket.create!(project_id: 1, number: 2, summary: "Test summary", type: "Bug")
    
    assert_difference "TicketQueue.named('unprioritized').count", +2 do
      TicketQueue.enter! "unprioritized", [ticket.id, ticket2.id]
    end
  end
  
  
  test "#exit! should record the time a number of tickets exited a queue" do
    queue = TicketQueue.create!(ticket: ticket, queue: "unprioritized")
    
    assert_no_difference "TicketQueue.named('unprioritized').count" do
      TicketQueue.exit! "unprioritized", [ticket.id]
    end
    
    assert queue.reload.destroyed_at, "TicketQueue#destroyed_at should now be present"
  end
  
  
end
