require 'test_helper'

class TicketTest < ActiveSupport::TestCase
  include RR::Adapters::TestUnit
  
  setup do
    Ticket.nosync = true
  end
  
  
  test "creating a valid ticket" do
    ticket = Ticket.new(project_id: 1, number: 1, summary: "Test summary", type: "Bug")
    assert_equal true, ticket.valid?
  end
  
  
  
  
  test "setting a ticket's queue creates a TicketQueue" do
    ticket = Ticket.create!(project_id: 1, number: 1, summary: "Test summary", type: "Bug")
    
    assert_difference "TicketQueue.count", +1 do
      ticket.set_queue! "to_do"
    end
    
    assert_equal "to_do", ticket.queue
  end
  
  
  test "updating a ticket's queue destroys the first TicketQueue and creates another one" do
    ticket = Ticket.create!(project_id: 1, number: 1, summary: "Test summary", type: "Bug")
    ticket.set_queue! "to_do"
    queue = ticket.ticket_queue
    
    assert_difference "TicketQueue.count", +1 do
      ticket.set_queue! "in_testing"
    end
    assert_equal true, queue.destroyed?
  end
  
  
  test "TicketQueues aren't destroyed or created when you set a ticket's queue to the same value" do
    ticket = Ticket.create!(project_id: 1, number: 1, summary: "Test summary", type: "Bug")
    ticket.set_queue! "to_do"
    queue = ticket.ticket_queue
    
    assert_no_difference "TicketQueue.count" do
      ticket.set_queue! "to_do"
    end
  end
  
  
  
  
  test "a ticket's queue can be mass-assigned on creation" do
    ticket = nil
    assert_difference "TicketQueue.count", +1 do
      ticket = Ticket.create!(project_id: 1, number: 1, summary: "Test summary", type: "Bug", queue: "to_do")
    end
    assert_equal "to_do", ticket.ticket_queue(true).queue
  end
  
  
  test "a ticket's queue can be mass-assigned on update" do
    ticket = Ticket.create!(project_id: 1, number: 1, summary: "Test summary", type: "Bug", queue: "to_do")
    assert_difference "TicketQueue.count", +1 do
      ticket.update_attributes(queue: "in_testing")
    end
    assert_equal "in_testing", ticket.ticket_queue(true).queue
  end
  
  
  
  
  test "invoking `release!` triggers the ticket:release event" do
    ticket = Ticket.create!(project_id: 1, number: 1, summary: "Test summary", type: "Bug")
    release = Release.new
    
    assert_triggered "ticket:release" do
      ticket.release!(release)
    end
  end
  
  test "invoking `release!` assigns first_release_at and last_release_at" do
    ticket = Ticket.create!(project_id: 1, number: 1, summary: "Test summary", type: "Bug")
    release = Release.new
    released_at = Time.now
    stub(release).created_at { released_at }
    
    ticket.release!(release)
    
    assert_equal released_at, ticket.first_release_at
    assert_equal released_at, ticket.last_release_at
  end
  
  test "invoking `release!` on a ticket that has been released assigns last_release_at" do
    project = Project.new(version_control_name: "Mock")
    ticket = Ticket.create!(project_id: 1, number: 1, summary: "Test summary", type: "Bug", first_release_at: 5.days.ago)
    ticket.releases << Release.create!(user_id: 1, project: project)
    release = Release.new
    released_at = Time.now
    stub(release).created_at { released_at }
    
    ticket.release!(release)
    
    refute_equal released_at, ticket.first_release_at
    assert_equal released_at, ticket.last_release_at
  end
  
  
  
  
  test "#tags accepts an array of strings" do
    ticket = Ticket.create!(project_id: 1, number: 1, summary: "Test summary", type: "Bug")
    ticket.tags = ["Bug", "No Work-Around"]
    assert_equal 2, ticket.tags.length
    assert_equal TicketTag, ticket.tags.first.class
    assert_equal ["Bug", "No Work-Around"], ticket.tags.map(&:name)
  end
  
  test "#tags accepts an array of TicketTag objects" do
    ticket = Ticket.create!(project_id: 1, number: 1, summary: "Test summary", type: "Bug")
    ticket.tags = [TicketTag.new("Bug", "b50000")]
    assert_equal 1, ticket.tags.length
    assert_equal TicketTag, ticket.tags.first.class
    assert_equal "Bug", ticket.tags.first.name
    assert_equal "b50000", ticket.tags.first.color
  end
  
  
end
