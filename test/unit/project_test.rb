require 'test_helper'

class ProjectTest < ActiveSupport::TestCase
  
  test "should validate version_control_location when a version control adapter is specified" do
    project = Project.new(version_control_adapter: "Git", version_control_location: "/wrong/path")
    project.valid?
    assert_match /Houston can't seem to connect to it/, project.errors.full_messages.to_sentence
  end
  
  test "should not validate version_control_location if no adapter is specified" do
    project = Project.new(version_control_adapter: "None", version_control_location: "/wrong/path")
    project.valid?
    assert_no_match /Houston can't seem to connect to it/, project.errors.full_messages.to_sentence
  end
  
end
