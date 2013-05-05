require 'test_helper'
require 'support/houston/adapters/version_control/mock_adapter'
require 'support/houston/adapters/ticket_tracker/mock_adapter'
require 'support/houston/adapters/ci_server/mock_adapter'

class ProjectTest < ActiveSupport::TestCase
  
  
  test "should validate version_control_location when a version control adapter is specified" do
    project = Project.new(version_control_name: "Git", version_control_location: "/wrong/path")
    project.valid?
    assert_match(/Houston can't seem to connect to it/, project.errors.full_messages.to_sentence)
  end
  
  test "should not validate version_control_location if no adapter is specified" do
    project = Project.new(version_control_name: "None", version_control_location: "/wrong/path")
    project.valid?
    assert_no_match(/Houston can't seem to connect to it/, project.errors.full_messages.to_sentence)
  end
  
  
  test "should find the specified built-in version control adapter" do
    project = Project.new(version_control_name: "None")
    assert_equal Houston::Adapters::VersionControl::NoneAdapter, project.version_control_adapter
  end
  
  test "should find the specified built-in ticket tracking adapter" do
    project = Project.new(ticket_tracker_name: "None")
    assert_equal Houston::Adapters::TicketTracker::NoneAdapter, project.ticket_tracker_adapter
  end
  
  test "should find the specified built-in CIServer adapter" do
    project = Project.new(ci_server_name: "None")
    assert_equal Houston::Adapters::CIServer::NoneAdapter, project.ci_server_adapter
  end
  
  test "should find the specified extension version control adapter" do
    project = Project.new(version_control_name: "Mock")
    assert_equal Houston::Adapters::VersionControl::MockAdapter, project.version_control_adapter
  end
  
  test "should find the specified extension ticket tracking adapter" do
    project = Project.new(ticket_tracker_name: "Mock")
    assert_equal Houston::Adapters::TicketTracker::MockAdapter, project.ticket_tracker_adapter
  end
  
  test "should find the specified extension CIServer adapter" do
    project = Project.new(ci_server_name: "Mock")
    assert_equal Houston::Adapters::CIServer::MockAdapter, project.ci_server_adapter
  end
  
  
end
