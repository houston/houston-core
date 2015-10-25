# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

# Load Houston
require "dummy/houston"
Rails.application.initialize! unless Rails.application.initialized?

require "rails/test_help"

if ENV["CI"] == "true"
  require "minitest/reporters"
  MiniTest::Reporters.use! [MiniTest::Reporters::DefaultReporter.new,
                            MiniTest::Reporters::JUnitReporter.new]
else
  require "minitest/reporters/turn_reporter"
  MiniTest::Reporters.use! Minitest::Reporters::TurnReporter.new
end

# Filter out Minitest backtrace while allowing backtrace
# from other libraries to be shown.
Minitest.backtrace_filter = Minitest::BacktraceFilter.new

class ActiveSupport::TestCase

  # Load fixtures from the engine
  self.fixture_path = File.expand_path("../fixtures", __FILE__)

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # Add more helper methods to be used by all tests here...

end

require "capybara/rails"

class ActionDispatch::IntegrationTest
  include Capybara::DSL

  # Load fixtures from the engine
  self.fixture_path = File.expand_path("../fixtures", __FILE__)

end
