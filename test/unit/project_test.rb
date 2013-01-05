require 'test_helper'
require 'support/houston/version_control/adapter/mock_adapter'
require 'support/houston/ticket_tracking/adapter/mock_adapter'
require 'support/houston/ci/adapter/mock_adapter'

class ProjectTest < ActiveSupport::TestCase
  
  
  test "should validate version_control_location when a version control adapter is specified" do
    project = Project.new(version_control_adapter: "Git", version_control_location: "/wrong/path")
    project.valid?
    assert_match(/Houston can't seem to connect to it/, project.errors.full_messages.to_sentence)
  end
  
  test "should not validate version_control_location if no adapter is specified" do
    project = Project.new(version_control_adapter: "None", version_control_location: "/wrong/path")
    project.valid?
    assert_no_match(/Houston can't seem to connect to it/, project.errors.full_messages.to_sentence)
  end
  
  
  test "should find the specified built-in version control adapter" do
    project = Project.new(version_control_adapter: "None")
    assert_equal Houston::VersionControl::Adapter::NoneAdapter, project.version_control_system
  end
  
  test "should find the specified built-in ticket tracking adapter" do
    project = Project.new(ticket_tracking_adapter: "None")
    assert_equal Houston::TicketTracking::Adapter::NoneAdapter, project.ticket_tracking_system
  end
  
  test "should find the specified built-in CI adapter" do
    project = Project.new(ci_adapter: "None")
    assert_equal Houston::CI::Adapter::NoneAdapter, project.ci_server
  end
  
  test "should find the specified extension version control adapter" do
    project = Project.new(version_control_adapter: "Mock")
    assert_equal Houston::VersionControl::Adapter::MockAdapter, project.version_control_system
  end
  
  test "should find the specified extension ticket tracking adapter" do
    project = Project.new(ticket_tracking_adapter: "Mock")
    assert_equal Houston::TicketTracking::Adapter::MockAdapter, project.ticket_tracking_system
  end
  
  test "should find the specified extension CI adapter" do
    project = Project.new(ci_adapter: "Mock")
    assert_equal Houston::CI::Adapter::MockAdapter, project.ci_server
  end
  
  
end
