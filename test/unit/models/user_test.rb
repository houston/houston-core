require 'test_helper'

class UserTest < ActiveSupport::TestCase
  attr_reader :user
  
  
  
  context "#email_addresses" do
    setup do
      @user = User.create!(
        first_name: "Gene",
        last_name: "Doyel",
        email: "gene@example.com",
        password: "password",
        password_confirmation: "password")
    end
    
    should "always include the primary email" do
      assert_equal %w{gene@example.com}, user.email_addresses, "User#email_addresses should be initialized with the value of User#email"
    end
    
    should "be unique" do
      user.alias_emails = %w{bob@example.com}
      refute user.valid?, "The user should be invalid because bob@example.com is in use"
      assert_match /bob@example\.com/, user.errors.full_messages.join("\n")
    end
  end
  
  context "#alias_emails" do
    setup do
      @user = User.first
    end
    
    should "list all a user's email addresses except the primary one" do
      assert_equal %w{bob@example.com}, user.email_addresses, "User#email_addresses should be initialized with the value of User#email"
      assert_equal [], user.alias_emails, "User#alias_emails should omit the user's primary email address"
    end
  end
  
  context "assigning #alias_emails" do
    setup do
      @user = User.first
    end
    
    should "update the list of all email addresses" do
      user.alias_emails = %w{bob@gmail.com}
      assert_equal %w{bob@example.com bob@gmail.com}, user.email_addresses
    end
  end
  
  context "changing #email" do
    setup do
      @user = User.first
      @user.alias_emails = %w{bob@gmail.com}
    end
    
    should "update the list of all email addresses and retain the former email address as an alias" do
      user.email = "bob@company.com"
      assert_equal %w{bob@company.com bob@example.com bob@gmail.com}, user.email_addresses
    end
  end
  
  
  
  context "with_email_address" do
    setup do
      @user = User.first
      @user.alias_emails = %w{bob@gmail.com}
      @user.save!
    end
    
    should "find users by any of their associated email addresses" do
      assert_equal 1, User.with_email_address("bob@example.com").count, "Should find the user by his primary email address"
      assert_equal 1, User.with_email_address("bob@gmail.com").count, "Should find the user by an alias email"
      assert_equal 1, User.with_email_address(%w{bob@example.com bob@gmail.com}).count, "Should find the user only once if two addresses match"
    end
    
    should "find users regardless of email case" do
      assert_equal 1, User.with_email_address("BOB@EXAMPLE.COM").count, "Should find the user by his primary email address even though that case is different"
    end
  end
  
  
  
end
