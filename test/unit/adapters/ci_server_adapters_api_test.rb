require 'test_helper'
require 'support/houston/adapters/ci_server/mock_adapter'

class CIServerAdatersApiTest < ActiveSupport::TestCase
  
  test "Houston::Adapters::CIServer.adapters finds all available adapters" do
    assert_equal %w{None Jenkins Mock}, Houston::Adapters::CIServer.adapters
  end
  
  Houston::Adapters::CIServer.adapters.each do |adapter_name|
    adapter = Houston::Adapters::CIServer.adapter(adapter_name)
    
    test "#{adapter.name} responds to the CIServer::Adapter interface" do
      assert_respond_to adapter, :errors_with_parameters
      assert_respond_to adapter, :build
      assert_respond_to adapter, :parameters
    end
    
    test "#{adapter.name}::Job responds to the CIServer::Job interface" do
      project = Project.new
      job = adapter.build(project)
      
      assert_respond_to job, :job_url
      assert_respond_to job, :build!
      assert_respond_to job, :fetch_results!
    end
  end
  
end
