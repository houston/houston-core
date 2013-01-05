require 'test_helper'
require 'support/houston/ticket_tracking/adapter/mock_adapter'

class TicketTrackingAdatersApiTest < ActiveSupport::TestCase
  
  test "Houston::TicketTracking.adapters finds all available adapters" do
    assert_equal 3, Houston::TicketTracking.adapters.count
  end
  
  connections = []
  Houston::TicketTracking.adapters.each do |adapter_name|
    adapter = Houston::TicketTracking.adapter(adapter_name)
    adapter = Houston::TicketTracking.adapter(adapter_name)
    connections << adapter.create_connection(1)
    
    test "#{adapter.name} responds to the TicketTracking::Adapter interface" do
      assert_respond_to adapter, :problems_with_project_id
      assert_respond_to adapter, :create_connection
    end
  end
  
  connections.uniq.each do |connection|
    test "#{connection.class.name} responds to the TicketTracking::Connection interface" do
      assert_respond_to connection, :construct_ticket_query
      assert_respond_to connection, :find_tickets!
      assert_respond_to connection, :project_url
      assert_respond_to connection, :ticket_url
      assert_respond_to connection, :find_custom_field_value_by_id!
      assert_respond_to connection, :find_custom_field_value_by_value!
      assert_respond_to connection, :ticket
      assert_respond_to connection, :get_ticket_attribute_for_custom_value_named!
    end
  end
  
end
