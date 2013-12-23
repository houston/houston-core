require 'test_helper'

class TicketTest < ActiveSupport::TestCase
  include RR::Adapters::TestUnit
  
  attr_reader :ticket, :release, :released_at
  
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
  
  
  
  
  context "#release!" do
    setup do
      @release = Release.new
      @released_at = Time.zone.now
      stub(@release).created_at { @released_at }
      
      @ticket = Ticket.create!(project_id: 1, number: 1, summary: "Test summary", type: "Bug")
    end
    
    should "trigger the ticket:release event" do
      assert_triggered "ticket:release" do
        ticket.release!(release)
      end
    end
    
    should "assign first_release_at and last_release_at" do
      ticket.release!(release)
      
      assert_equal released_at, ticket.first_release_at
      assert_equal released_at, ticket.last_release_at
    end
    
    context "on a ticket that has been released" do
      setup do
        project = Project.new(version_control_name: "Mock")
        @ticket.update_column :first_release_at, 5.days.ago
        @ticket.releases << Release.create!(user_id: 1, project: project)
      end
      
      should "assign last_release_at" do
        ticket.release!(release)
        
        assert_equal released_at, ticket.last_release_at
      end
      
      should "not assign first_release_at" do
        ticket.release!(release)
        
        refute_equal released_at, ticket.first_release_at
      end
      
      context "and reopened" do
        setup do
          ticket.update_column :reopened_at, 1.hour.ago
        end
        
        should "assign first_release_at" do
          ticket.release!(release)
          
          assert_equal released_at, ticket.first_release_at
        end
      end
    end
  end
  
  
  
  context "#reopen!" do
    setup do
      @ticket = Ticket.create!(
        project_id: 1,
        number: 1,
        summary: "Test summary",
        resolution: "fixed",
        first_release_at: 1.year.ago,
        last_release_at: 1.month.ago,
        type: "Bug")
    end
    
    context "a closed ticket" do
      setup do
        ticket.update_column :closed_at, Time.now
      end
      
      should "raise an exception if the ticket is closed" do
        assert_raises RuntimeError do
          ticket.reopen!
        end
      end
    end
    
    context "an unresolved ticket" do
      setup do
        ticket.update_column :resolution, ""
      end
      
      should "do nothing" do
        mock(ticket).remote_ticket.never
        mock(ticket).update_attributes.never
        
        ticket.reopen!
      end
    end
    
    should "send #reopen! to #remote_ticket" do
      remote_ticket = Object.new.tap do |remote_ticket|
        mock(remote_ticket).reopen! { }
      end
      mock(ticket).remote_ticket { remote_ticket }.at_least(1)
      
      ticket.reopen!
    end
    
    should "touch the reopened_at timestamp" do
      Timecop.freeze Time.zone.now do
        ticket.reopen!
        assert_equal Time.zone.now, ticket.reopened_at
      end
    end
    
    should "clear first_release_at and last_release_at" do
      ticket.reopen!
      
      refute ticket.first_release_at, "Ticket#reopen! should reset Ticket#first_release_at"
      refute ticket.last_release_at, "Ticket#reopen! should reset Ticket#last_release_at"
    end
  end
  
  
  
  context "#tags" do
    setup do
      @ticket = Ticket.create!(project_id: 1, number: 1, summary: "Test summary", type: "Bug")
    end
    
    should "accept an array of strings" do
      ticket.tags = ["Bug", "No Work-Around"]
      assert_equal 2, ticket.tags.length
      assert_equal TicketTag, ticket.tags.first.class
      assert_equal ["Bug", "No Work-Around"], ticket.tags.map(&:name)
    end
    
    should "accept an array of TicketTag objects" do
      ticket.tags = [TicketTag.new("Bug", "b50000")]
      assert_equal 1, ticket.tags.length
      assert_equal TicketTag, ticket.tags.first.class
      assert_equal "Bug", ticket.tags.first.name
      assert_equal "b50000", ticket.tags.first.color
    end
  end
  
  
  
end
