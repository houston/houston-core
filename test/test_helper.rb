ENV["RAILS_ENV"] ||= "test"

if ENV["COVERAGE"] == "on"
  require "simplecov"
  require "simplecov-json"
  SimpleCov.formatter = SimpleCov::Formatter::JSONFormatter
  SimpleCov.start "rails"
end

require File.expand_path("../../config/application", __FILE__)
require_relative "support/config"
Rails.application.initialize!

require "rails/test_help"
require "capybara/rails"
require "minitest/reporters/turn_reporter"
require "houston/test_helpers"

if ENV["CI"] == "true"
  require "minitest/reporters"
  MiniTest::Reporters.use! [Minitest::Reporters::TurnReporter.new,
                            MiniTest::Reporters::JUnitReporter.new]
else
  MiniTest::Reporters.use! Minitest::Reporters::TurnReporter.new
end



Houston.observer.async = false



class ActiveSupport::TestCase
  ActiveRecord::Migration.check_pending! unless ENV["CI"] == "true"
  include FactoryGirl::Syntax::Methods
  include Houston::TestHelpers

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  fixtures :all

  # Add more helper methods to be used by all tests here...


  def refute_raises(*exp)
    msg = "#{exp.pop}.\n" if String === exp.last
    exp << StandardError if exp.empty?

    yield

    pass
  rescue *exp => e
    exp = exp.first if exp.size == 1
    flunk "#{msg}#{mu_pp(exp)} was not supposed to be raised"
  end

end

class ActionController::TestCase
  include Devise::Test::ControllerHelpers
end
