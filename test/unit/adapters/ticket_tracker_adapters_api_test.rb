require "test_helper"
require "support/houston/adapters/ticket_tracker/mock_adapter"

class TicketTrackerAdatersApiTest < ActiveSupport::TestCase

  test "Houston::Adapters::TicketTracker.adapters finds all available adapters" do
    assert_equal %w{None Github Houston Mock Unfuddle}, Houston::Adapters::TicketTracker.adapters
  end

  connections = []
  Houston::Adapters::TicketTracker.adapters.each do |adapter_name|
    adapter = Houston::Adapters::TicketTracker.adapter(adapter_name)
    connections << adapter.build(Project.new, 1).extend(FeatureSupport)

    test "#{adapter.name} responds to the TicketTracker::Adapter interface" do
      assert_respond_to adapter, :errors_with_parameters
      assert_respond_to adapter, :build
      assert_respond_to adapter, :parameters
    end
  end

  tickets = []
  connections.uniq.each do |connection|
    tickets << connection.build_ticket({})

    test "#{connection.class.name} responds to the TicketTracker::Connection interface" do
      assert_respond_to connection, :features
      assert_respond_to connection, :build_ticket # <-- for creating a TicketTracker::Ticket from a native ticket,
                                                  #     used internally except for this test...
      assert_respond_to connection, :create_ticket! # <-- for creating a remote ticket from attributes
      assert_respond_to connection, :find_ticket_by_number
      assert_respond_to connection, :project_url
      assert_respond_to connection, :ticket_url

      if connection.supports? :syncing_tickets
        assert_respond_to connection, :find_tickets_numbered
        assert_respond_to connection, :all_tickets
        assert_respond_to connection, :open_tickets
      end

      if connection.supports? :syncing_milestones
        assert_respond_to connection, :all_milestones
        assert_respond_to connection, :open_milestones
      end
    end
  end

  tickets.uniq.each do |ticket|
    test "#{ticket.class.name} responds to the TicketTracker::Ticket interface" do
      assert_respond_to ticket, :remote_id
      assert_respond_to ticket, :number
      assert_respond_to ticket, :summary
      assert_respond_to ticket, :description
      assert_respond_to ticket, :reporter_email
      assert_respond_to ticket, :milestone_id
      assert_respond_to ticket, :type
      assert_respond_to ticket, :tags
      assert_respond_to ticket, :created_at
      assert_respond_to ticket, :closed_at

      assert_respond_to ticket, :close!
      assert_respond_to ticket, :reopen!
    end
  end

end
