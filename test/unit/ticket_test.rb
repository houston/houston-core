require 'test_helper'

class TicketTest < ActiveSupport::TestCase
  
  
  test "creating a valid ticket" do
    ticket = Ticket.new(project_id: 1, number: 1, summary: "Test summary")
    assert_equal true, ticket.valid?
  end
  
  
  
  
  test "setting a ticket's queue creates a TicketQueue" do
    ticket = Ticket.create(project_id: 1, number: 1, summary: "Test summary")
    
    assert_difference "TicketQueue.count", +1 do
      ticket.set_queue! "in_development"
    end
    
    assert_equal "in_development", ticket.queue
  end
  
  
  test "updating a ticket's queue destroys the first TicketQueue and creates another one" do
    ticket = Ticket.create(project_id: 1, number: 1, summary: "Test summary")
    ticket.set_queue! "in_development"
    queue = ticket.ticket_queue
    
    assert_difference "TicketQueue.count", +1 do
      ticket.set_queue! "in_testing"
    end
    assert_equal true, queue.destroyed?
  end
  
  
  
  
  test "a ticket's queue can be mass-assigned on creation" do
    ticket = nil
    assert_difference "TicketQueue.count", +1 do
      ticket = Ticket.create(project_id: 1, number: 1, summary: "Test summary", queue: "in_development")
    end
    assert_equal "in_development", ticket.ticket_queue(true).queue
  end
  
  
  test "a ticket's queue can be mass-assigned on update" do
    ticket = Ticket.create(project_id: 1, number: 1, summary: "Test summary", queue: "in_development")
    assert_difference "TicketQueue.count", +1 do
      ticket.update_attributes(queue: "in_testing")
    end
    assert_equal "in_testing", ticket.ticket_queue(true).queue
  end
  
  
end
