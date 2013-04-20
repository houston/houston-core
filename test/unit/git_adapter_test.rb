require 'test_helper'

class GitAdapterTest < ActiveSupport::TestCase
  
  setup do
    path = Rails.root.join("test", "data", "bare_repo.git")
    @test_repo = Houston::VersionControl::Adapter::GitAdapter.build(path)
  end
  
  
  test "#git_dir should return path when the repo is bare" do
    path = Rails.root.join("test", "data", "bare_repo.git")
    repo = Houston::VersionControl::Adapter::GitAdapter.build(path)
    assert_equal path.to_s, repo.send(:git_dir)
  end
  
  test "#git_dir should return the .git subdirectory when the repo is not bare" do
    path = Rails.root
    repo = Houston::VersionControl::Adapter::GitAdapter.build(path)
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
  
  
  test "#read_file should return the contents of a named file" do
    readme = <<-STR
fixture
=======

This repo is a fixture for Houston's tests
STR
    assert_equal readme, @test_repo.read_file("README.md")
  end
  
  test "#read_file should return nil for files that don't exist" do
    assert_equal nil, @test_repo.read_file("NOPE.md")
  end
  
  
  test "#commits_between should return an array of commits excluding the first and including the last" do
    sha0 = "b62c3f32f72423b81a0282a1a4b97cad2cf129d4"
    sha1 = "22924bbf4378f83cab93bfd5fa7d7777cbc1f3b4"
    commits = @test_repo.commits_between(sha0, sha1)
    assert_equal 2, commits.length
    assert_instance_of Houston::VersionControl::Commit, commits.first
  end
  
  
  test "Commit messages should be UTF-8" do
    commit = @test_repo.native_commit("22924bbf4378f83cab93bfd5fa7d7777cbc1f3b4")
    assert_equal "UTF-8", commit.message.encoding.name
  end
  
  
  test "should return a NullRepo if you give it an invalid path" do
    path = Rails.root.join("nope")
    repo = Houston::VersionControl::Adapter::GitAdapter.build(path)
    assert_equal Houston::VersionControl::NullRepo, repo
  end
  
  
end
