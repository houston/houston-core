require "test_helper"

class GitAdapterTest < ActiveSupport::TestCase
  include Houston::Adapters::VersionControl
  attr_reader :remote_path, :repo



  setup do
    @repo = new_local_repo
  end



  test "#git_dir should return path when the repo is bare" do
    repo = GitAdapter.build(Project.new, test_path)
    assert_equal test_path, repo.send(:git_dir)
  end

  test "#git_dir should return the .git subdirectory when the repo is not bare" do
    path = Rails.root
    repo = GitAdapter.build(Project.new, path)
    assert_equal path.join(".git").to_s, repo.send(:git_dir)
  end



  %w{local remote}.each do |repo_location|
    context "With a #{repo_location} repo," do
      setup do
        @repo = repo_location == "local" ? new_local_repo : new_remote_repo
      end

      context "#branches_at" do
        should "return the names of the branches that point to a given commit" do
          sha = "b62c3f32f72423b81a0282a1a4b97cad2cf129d4"
          branches = repo.branches_at(sha)
          assert branches.member?("for-testing"), "'for-testing' was expected to point at '#{sha}'; but Houston found these branches: [#{branches.join(", ")}]"
        end

        should "return an empty array if no branches point to a given commit" do
          sha = "whatever"
          assert_equal [], repo.branches_at(sha)
        end
      end
    end
  end



  test "#read_file should return the contents of a named file" do
    readme = <<-STR
fixture
=======

This repo is a fixture for Houston's tests
STR
    assert_equal readme, repo.read_file("README.md")
  end

  test "#read_file should return nil for files that don't exist" do
    assert_equal nil, repo.read_file("NOPE.md")
  end


  test "#commits_between should return an array of commits excluding the first and including the last" do
    sha0 = "b62c3f32f72423b81a0282a1a4b97cad2cf129d4"
    sha1 = "22924bbf4378f83cab93bfd5fa7d7777cbc1f3b4"
    commits = repo.commits_between(sha0, sha1)
    assert_equal "22924bb", commits.last.to_s, "Expected the last commit to be #{sha1}"
    assert_equal "bd3e9e2", commits.first.to_s, "Expected the first commit to be the one _after_ #{sha0}"
    assert_equal 2, commits.length
    assert_instance_of Commit, commits.first
  end

  test "#commits_between should return all commits when the first sha is 0000000000000000000000000000000000000000" do
    sha0 = "0000000000000000000000000000000000000000"
    sha1 = "22924bbf4378f83cab93bfd5fa7d7777cbc1f3b4"
    commits = repo.commits_between(sha0, sha1)
    assert_equal "22924bb", commits.last.to_s, "Expected the last commit to be #{sha1}"
    assert_equal "b62c3f3", commits.first.to_s, "Expected the first commit to be the first commit reachable from #{sha1}"
    assert_equal 3, commits.length
    assert_instance_of Commit, commits.first
  end

  test "#ancestors should return an array of commits that are reachable from the given sha" do
    sha1 = "baa3ef2" # "When you have eliminated the impossible, what remains," (divergent-branch)
    sha2 = "22924bb" # "Create README.md" (master)

    assert_equal %w{b3d156e bd3e9e2 b62c3f3}, repo.ancestors(sha1).map(&:to_s)
    assert_equal         %w{bd3e9e2 b62c3f3}, repo.ancestors(sha2).map(&:to_s)
  end


  test "Commit messages should be UTF-8" do
    commit = repo.native_commit("22924bbf4378f83cab93bfd5fa7d7777cbc1f3b4")
    assert_equal "UTF-8", commit.message.encoding.name
  end


  context "Looking up a commit" do
    should "disregard trailing white space" do
      commit = repo.native_commit("22924bbf4378f83cab93bfd5fa7d7777cbc1f3b4\r\n")
      assert commit, "Expected to find the commit in spite of the trailing line break"
    end
  end



  test "should return a NullRepo if you give it an invalid path" do
    repo = GitAdapter.build Project.new, Rails.root.join("nope")
    assert_equal Houston::Adapters::VersionControl::NullRepo, repo
  end

  test "should return a NullRepo if you give it an invalid endpoint" do
    repo = GitAdapter.build Project.new, "git@github.com:houston/nope.git"
    assert_equal Houston::Adapters::VersionControl::NullRepo, repo
  end



  test "RemoteRepo should try pulling changes when a commit is not found" do
    repo = new_remote_repo
    connection = repo.send :connection
    stub(connection).lookup { |*args| raise CommitNotFound }
    stub(connection).close
    mock(repo).pull!(async: false)

    assert_raises CommitNotFound do
      repo.commits_between("aaaaaaa", "bbbbbbb")
    end
  end



  context "clone!" do
    setup do
      system "rm -rf #{Shellwords.escape temporary_path}"
    end

    should "work with a remote repo using the SSH transport" do
      remote_path = "git@github.com:houston/fixture.git"
      GitAdapter::RemoteRepo.new(temporary_path, remote_path).clone!
      assert File.exists?(fetch_head)
    end

    should "work with a remote repo using the Git transport" do
      remote_path = "git://github.com/houston/fixture.git"
      GitAdapter::RemoteRepo.new(temporary_path, remote_path).clone!
      assert File.exists?(fetch_head)
    end
  end



  context "#pull" do
    setup do
      system "rm -rf #{Shellwords.escape temporary_path}"
      @repo = new_remote_repo
    end

    should "create missing refs" do
      rugged_repo.references.delete "refs/remotes/origin/for-testing"
      references = rugged_repo.references.map(&:name)

      repo.pull!

      new_references = rugged_repo.references.map(&:name) - references
      assert_equal ["refs/remotes/origin/for-testing"], new_references
    end

    should "prune removed refs" do
      rugged_repo.references.create("refs/remotes/origin/baleeted", rugged_repo.head.target.oid)
      references = rugged_repo.references.map(&:name)

      repo.pull!

      pruned_references = references - rugged_repo.references.map(&:name)
      assert_equal ["refs/remotes/origin/baleeted"], pruned_references
    end
  end



private

  def new_local_repo
    GitAdapter.connect test_path, test_path
  end

  def new_remote_repo
    GitAdapter.connect "git://github.com/houston/fixture.git", temporary_path
  end

  def test_path
    @test_path ||= Rails.root.join("test", "data", "bare_repo.git").to_s
  end

  def temporary_path
    @temporary_path ||= Rails.root.join("tmp", Time.now.strftime("%Y%m%dT%H%M%S"))
  end

  def fetch_head
    @fetch_head ||= temporary_path.join("HEAD").to_s
  end

  def rugged_repo
    @rugged_repo ||= repo.send :connection
  end

end
