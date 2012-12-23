require 'test_helper'

class GitAdapterTest < ActiveSupport::TestCase
  
  test "#git_dir should return path when the repo is bare" do
    path = Rails.root.join("tmp", "unite.git")
    repo = Houston::VersionControl::Adapter::GitAdapter.create_repo(path)
    assert_equal path.to_s, repo.git_dir
  end
  
  test "#git_dir should return the .git subdirectory when the repo is not bare" do
    path = Rails.root
    repo = Houston::VersionControl::Adapter::GitAdapter.create_repo(path)
    assert_equal path.join(".git").to_s, repo.git_dir
  end
  
end
