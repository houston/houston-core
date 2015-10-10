require "test_helper"

class ReleaseChangeTest < ActiveSupport::TestCase

  setup do
    Houston.config do
      change_tags( {name: "New Feature", as: "feature", color: "8DB500"},
                   {name: "Bugfix", as: "fix", color: "C64537", aliases: %w{bugfix}} )
    end
  end

  test "should have a tag when created for a slug that has been associated with a tag" do
    commit = Commit.new(message: "[feature] did lots of work")
    change = ReleaseChange.from_commit(nil, commit)
    assert_not_nil change.tag
    assert_equal "New Feature", change.tag.name
  end

  test "should have a tag when created for a slug that has been aliased to a tag" do
    commit = Commit.new(message: "[bugfix] did lots of work")
    change = ReleaseChange.from_commit(nil, commit)
    assert_not_nil change.tag
    assert_equal "Bugfix", change.tag.name
  end

  test "should have NullTag when created for a slug that has not been defined" do
    commit = Commit.new(message: "[nope] did lots of work")
    change = ReleaseChange.from_commit(nil, commit)
    assert_equal NullTag.instance, change.tag
  end

end
