require 'test_helper'

class ReleaseTest < ActiveSupport::TestCase
  include RR::Adapters::TestUnit
  
  
  test "a new release triggers invokes `release!` on each ticket" do
    release = Release.new(user_id: 1)
    a_ticket = Object.new
    
    stub(release).native_commits! { nil }
    mock(release).tickets { [a_ticket] }
    mock(a_ticket).release!(release)
    
    release.save!
  end
  
  
end
