require 'test_helper'
require 'support/houston/ticket_tracking/adapter/mock_adapter'

class TicketTrackingAdatersApiTest < ActiveSupport::TestCase
  
  test "Houston::TicketTracking.adapters finds all available adapters" do
    assert_equal 3, Houston::TicketTracking.adapters.count
  end
  
  connections = []
  Houston::TicketTracking.adapters.each do |adapter_name|
    adapter = Houston::TicketTracking.adapter(adapter_name)
    connections << adapter.create_connection(1)
    
    test "#{adapter.name} responds to the TicketTracking::Adapter interface" do
      assert_respond_to adapter, :problems_with_project_id
      assert_respond_to adapter, :create_connection
    end
  end
  
  tickets = []
  connections.uniq.each do |connection|
    tickets << connection.build_ticket({})
    
    test "#{connection.class.name} responds to the TicketTracking::Connection interface" do
      assert_respond_to connection, :build_ticket
      assert_respond_to connection, :find_ticket
      assert_respond_to connection, :find_tickets!
      
      assert_respond_to connection, :construct_ticket_query
      assert_respond_to connection, :project_url
      assert_respond_to connection, :ticket_url
    end
  end
  
  tickets.uniq.each do |ticket|
    test "#{ticket.class.name} responds to the TicketTracking::Ticket interface" do
      assert_respond_to ticket, :remote_id
      assert_respond_to ticket, :number
      assert_respond_to ticket, :summary
      assert_respond_to ticket, :description
      assert_respond_to ticket, :deployment
      assert_respond_to ticket, :goldmine
      assert_respond_to ticket, :update_attribute
    end
  end
  
end
