require 'test_helper'

class GitAdapterTest < ActiveSupport::TestCase
  
  setup do
    path = Rails.root.join("test", "data", "bare_repo.git")
    @test_repo = Houston::VersionControl::Adapter::GitAdapter.create_repo(path)
  end
  
  
  test "#git_dir should return path when the repo is bare" do
    path = Rails.root.join("test", "data", "bare_repo.git")
    repo = Houston::VersionControl::Adapter::GitAdapter.create_repo(path)
    assert_equal path.to_s, repo.send(:git_dir)
  end
  
  test "#git_dir should return the .git subdirectory when the repo is not bare" do
    path = Rails.root
    repo = Houston::VersionControl::Adapter::GitAdapter.create_repo(path)
    assert_equal path.join(".git").to_s, repo.send(:git_dir)
  end
  
  
  test "#branches_at should return the names of the branches that point to a given commit" do
    sha = "b62c3f32f72423b81a0282a1a4b97cad2cf129d4"
    branches = @test_repo.branches_at(sha)
    assert branches.member?("for-testing"), "'for-testing' was expected to point at '#{sha}'; but Houston found these branches: [#{branches.join(", ")}]"
  end
  
  test "#branches_at should return an empty array if no branches point to a given commit" do
    sha = "whatever"
    assert_equal [], @test_repo.branches_at(sha)
  end
  
  
end
