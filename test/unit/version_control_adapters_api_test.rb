require 'test_helper'
require 'support/houston/version_control/adapter/mock_adapter'

class VersionControlAdatersApiTest < ActiveSupport::TestCase
  
  test "Houston::VersionControl.adapters finds all available adapters" do
    assert_equal 3, Houston::VersionControl.adapters.count
  end
  
  repos = []
  Houston::VersionControl.adapters.each do |adapter_name|
    adapter = Houston::VersionControl.adapter(adapter_name)
    repo_location = Rails.root.join("test", "data", "bare_repo.git")
    repos << adapter.build(repo_location)
    
    test "#{adapter.name} responds to the VersionControl::Adapter interface" do
      assert_respond_to adapter, :errors_with_parameters
      assert_respond_to adapter, :build
    end
  end
  
  repos.uniq.each do |repo|
    test "#{repo.class.name} responds to the VersionControl::Repo interface" do
      assert_respond_to repo, :all_commit_times
      assert_respond_to repo, :branches_at
      assert_respond_to repo, :commits_between
      assert_respond_to repo, :native_commit
      assert_respond_to repo, :read_file
      assert_respond_to repo, :refresh!
    end
  end
  
end
