require 'test_helper'

class TicketTest < ActiveSupport::TestCase
  
  
  test "creating a valid ticket" do
    ticket = Ticket.new(number: 1, summary: "Test summary")
    assert_equal true, ticket.valid?
  end
  
  
  test "setting a ticket's queue creates a TicketQueue" do
    ticket = Ticket.create(number: 1, summary: "Test summary")
    
    assert_difference "TicketQueue.count", +1 do
      ticket.set_queue! "Queue 1"
    end
    
    assert_equal "Queue 1", ticket.queue
  end
  
  
  test "updating a ticket's queue destroys the first TicketQueue and creates another one" do
    ticket = Ticket.create(number: 1, summary: "Test summary")
    ticket.set_queue! "Queue 1"
    queue = ticket.ticket_queue
    
    assert_difference "TicketQueue.count", +1 do
      ticket.set_queue! "Queue 2"
    end
    assert_equal true, queue.destroyed?
  end
  
  
  
  
  test "a ticket's queue can be mass-assigned on creation" do
    ticket = nil
    assert_difference "TicketQueue.count", +1 do
      ticket = Ticket.create(number: 1, summary: "Test summary", queue: "Queue 1")
    end
    assert_equal "Queue 1", ticket.ticket_queue(true).queue
  end
  
  
  test "a ticket's queue can be mass-assigned on update" do
    ticket = Ticket.create(number: 1, summary: "Test summary", queue: "Queue 1")
    assert_difference "TicketQueue.count", +1 do
      ticket.update_attributes(queue: "Queue 2")
    end
    assert_equal "Queue 2", ticket.ticket_queue(true).queue
  end
  
  
  
end
