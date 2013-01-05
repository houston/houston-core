require 'test_helper'
require 'support/houston/ci/adapter/mock_adapter'

class CIAdatersApiTest < ActiveSupport::TestCase
  
  test "Houston::CI.adapters finds all available adapters" do
    assert_equal 3, Houston::CI.adapters.count
  end
  
  Houston::CI.adapters.each do |adapter_name|
    adapter = Houston::CI.adapter(adapter_name)
    
    test "#{adapter.name} responds to the CI::Adapter interface" do
      assert_respond_to adapter, :job_for_project
    end
    
    test "#{adapter.name}::Job responds to the CI::Job interface" do
      project = Project.new
      job = adapter.job_for_project(project)
      
      assert_respond_to job, :build!
    end
  end
  
end
