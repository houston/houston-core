require 'test_helper'
require 'support/houston/ci/adapter/mock_adapter'

class CIAdatersApiTest < ActiveSupport::TestCase
  
  test "Houston::CI.adapters finds all available adapters" do
    assert_equal 3, Houston::CI.adapters.count
  end
  
  Houston::CI.adapters.each do |adapter_name|
    adapter = Houston::CI.adapter(adapter_name)
    
    test "#{adapter.name} responds to the CI::Adapter interface" do
    end
  end
  
end
