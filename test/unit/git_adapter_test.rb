require 'test_helper'

class GitAdapterTest < ActiveSupport::TestCase
  include RR::Adapters::TestUnit
  
  setup do
    path = Rails.root.join("test", "data", "bare_repo.git")
    @test_repo = Houston::Adapters::VersionControl::GitAdapter.build(Project.new, path)
  end
  
  
  test "#git_dir should return path when the repo is bare" do
    path = Rails.root.join("test", "data", "bare_repo.git")
    repo = Houston::Adapters::VersionControl::GitAdapter.build(Project.new, path)
    assert_equal path.to_s, repo.send(:git_dir)
  end
  
  test "#git_dir should return the .git subdirectory when the repo is not bare" do
    path = Rails.root
    repo = Houston::Adapters::VersionControl::GitAdapter.build(Project.new, path)
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
    assert_equal "22924bb", commits.last.to_s, "Expected the last commit to be the one _before_ #{sha1}"
    assert_equal "bd3e9e2", commits.first.to_s, "Expected the first commit to be the one _after_ #{sha0}"
    assert_equal 2, commits.length
    assert_instance_of Houston::Adapters::VersionControl::Commit, commits.first
  end
  
  test "#ancestors should return an array of commits that are reachable from the given sha" do
    sha1 = "baa3ef2" # "When you have eliminated the impossible, what remains," (divergent-branch)
    sha2 = "22924bb" # "Create README.md" (master)
    
    assert_equal %w{b3d156e bd3e9e2 b62c3f3}, @test_repo.ancestors(sha1).map(&:to_s)
    assert_equal         %w{bd3e9e2 b62c3f3}, @test_repo.ancestors(sha2).map(&:to_s)
  end
  
  
  test "Commit messages should be UTF-8" do
    commit = @test_repo.native_commit("22924bbf4378f83cab93bfd5fa7d7777cbc1f3b4")
    assert_equal "UTF-8", commit.message.encoding.name
  end
  
  
  test "should return a NullRepo if you give it an invalid path" do
    path = Rails.root.join("nope")
    repo = Houston::Adapters::VersionControl::GitAdapter.build(Project.new, path)
    assert_equal Houston::Adapters::VersionControl::NullRepo, repo
  end
  
  
  test "RemoteRepo should try pulling changes when a commit is not found" do
    remote_path = "git@github.com:houstonmc/houston.git"
    local_path = Rails.root.join("test", "data", "bare_repo.git").to_s
    connection = OpenStruct.new(path: local_path)
    stub(connection).lookup { |*args| raise Houston::Adapters::VersionControl::CommitNotFound }
    
    mock(Houston::Adapters::VersionControl::GitAdapter).pull!(local_path) { }
    
    assert_raises Houston::Adapters::VersionControl::CommitNotFound do
      repo = Houston::Adapters::VersionControl::GitAdapter::RemoteRepo.new(connection, remote_path)
      repo.commits_between("aaaaaaa", "bbbbbbb")
    end
  end
  
  
end
