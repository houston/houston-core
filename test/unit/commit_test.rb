require 'test_helper'

class CommitTest < ActiveSupport::TestCase
  
  test "should extract an array of tags from the front of a commit" do
    commits = [
      "[skip] don't look at me",
      "[new-feature] i'm fancy",
      "[fix] [refactor] [c_i] i don't like talking about my flare",
      "[tight-fit]right up by the text"
    ]
    
    expectations = [
      %w{skip},
      %w{new-feature},
      %w{fix refactor c_i},
      %w{tight-fit}
    ]
    
    commits.zip(expectations) do |commit_message, expectation|
      assert_equal expectation, Commit.new(message: commit_message).tags
    end
  end
  
  test "should extract an array of tickets from the end of a commit" do
    commits = [
      "I did some work [#1347]"
    ]
    
    expectations = [
      ["1347"]
    ]
    
    commits.zip(expectations) do |commit_message, expectation|
      assert_equal expectation, Commit.new(message: commit_message).ticket_numbers
    end
  end
  
  test "should extract extra attributes from a commit" do
    commits = [
      "I did some work {{attr:value}}",
      "I set this one twice {{attr:v1}} {{attr:v2}}"
    ]
    
    expectations = [
      {"attr" => ["value"]},
      {"attr" => ["v1", "v2"]}
    ]
    
    commits.zip(expectations) do |commit_message, expectation|
      assert_equal expectation, Commit.new(message: commit_message).extra_attributes
    end
  end
  
  test "should extract a clean message from a commit" do
    commits = [
      "[tag] I did some work {{attr:value}} [#45]"
    ]
    
    expectations = [
      "I did some work"
    ]
    
    commits.zip(expectations) do |commit_message, expectation|
      assert_equal expectation, Commit.new(message: commit_message).clean_message
    end
  end
  
end
