require 'test_helper'
require 'support/houston/adapters/version_control/mock_adapter'

class VersionControlAdatersApiTest < ActiveSupport::TestCase
  
  test "Houston::Adapters::VersionControl.adapters finds all available adapters" do
    assert_equal %w{None Git Mock}, Houston::Adapters::VersionControl.adapters
  end
  
  repos = []
  Houston::Adapters::VersionControl.adapters.each do |adapter_name|
    adapter = Houston::Adapters::VersionControl.adapter(adapter_name)
    repo_location = Rails.root.join("test", "data", "bare_repo.git")
    repos << adapter.build(Project.new, repo_location)
    
    test "#{adapter.name} responds to the VersionControl::Adapter interface" do
      assert_respond_to adapter, :errors_with_parameters
      assert_respond_to adapter, :build
      assert_respond_to adapter, :parameters
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
