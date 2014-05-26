require 'test_helper'

class ReleaseChangeTest < ActiveSupport::TestCase
  
  test "should have a tag when created for a slug that has been associated with a tag" do
    commit = Commit.new(message: "[feature] did lots of work")
    change = ReleaseChange.from_commit(nil, commit)
    assert_not_nil change.tag
    assert_equal "New Feature", change.tag.name
  end
  
  test "should have a tag when created for a slug that has been aliased to a tag" do
    commit = Commit.new(message: "[ciskip] did lots of work")
    change = ReleaseChange.from_commit(nil, commit)
    assert_not_nil change.tag
    assert_equal "CI Fix", change.tag.name
  end
  
  test "should have NullTag when created for a slug that has not been defined" do
    commit = Commit.new(message: "[nope] did lots of work")
    change = ReleaseChange.from_commit(nil, commit)
    assert_equal NullTag.instance, change.tag
  end
  
end
