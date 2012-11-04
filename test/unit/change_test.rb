require 'test_helper'

class ChangeTest < ActiveSupport::TestCase
  
  test "should have a tag when created for a slug that hasn't been tagified yet" do
    commit = Commit.new(message: "[new-tag] did lots of work")
    change = Change.from_commit(commit)
    assert_not_nil change.tag
    assert_equal "New Tag", change.tag.name
  end
  
  test "should have a tag when created for a slug that already has been tagified" do
    existing_tag = Tag.create!(name: "Some Tag")
    
    commit = Commit.new(message: "[some_tag] did lots of work")
    change = Change.from_commit(commit)
    assert_equal existing_tag.id, change.tag.id
  end
  
end
