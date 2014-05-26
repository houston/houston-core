require "test_helper"
require "support/houston/adapters/version_control/mock_adapter"
require "support/houston/adapters/ticket_tracker/mock_adapter"
require "support/houston/adapters/ci_server/mock_adapter"


class ProjectTest < ActiveSupport::TestCase
  
  
  context "Validation:" do
    should "validate version control parameters when a version control adapter is specified" do
      project = Project.new(version_control_name: "Git", extended_attributes: {"git_location" => "/wrong/path"})
      project.valid?
      assert_match(/Houston can't seem to connect to it/, project.errors.full_messages.to_sentence)
    end
    
    should "not validate version control parameters if no adapter is specified" do
      project = Project.new(version_control_name: "None", extended_attributes: {"git_location" => "/wrong/path"})
      project.valid?
      assert_no_match(/Houston can't seem to connect to it/, project.errors.full_messages.to_sentence)
    end
  end
  
  
  context "Adapters:" do
    should "find the specified built-in version control adapter" do
      project = Project.new(version_control_name: "None")
      assert_equal Houston::Adapters::VersionControl::NoneAdapter, project.version_control_adapter
    end
    
    should "find the specified built-in ticket tracking adapter" do
      project = Project.new(ticket_tracker_name: "None")
      assert_equal Houston::Adapters::TicketTracker::NoneAdapter, project.ticket_tracker_adapter
    end
    
    should "find the specified built-in CIServer adapter" do
      project = Project.new(ci_server_name: "None")
      assert_equal Houston::Adapters::CIServer::NoneAdapter, project.ci_server_adapter
    end
    
    should "find the specified extension version control adapter" do
      project = Project.new(version_control_name: "Mock")
      assert_equal Houston::Adapters::VersionControl::MockAdapter, project.version_control_adapter
    end
    
    should "find the specified extension ticket tracking adapter" do
      project = Project.new(ticket_tracker_name: "Mock")
      assert_equal Houston::Adapters::TicketTracker::MockAdapter, project.ticket_tracker_adapter
    end
    
    should "find the specified extension CIServer adapter" do
      project = Project.new(ci_server_name: "Mock")
      assert_equal Houston::Adapters::CIServer::MockAdapter, project.ci_server_adapter
    end
  end
  
  
end
