if ENV['COVERAGE'] == 'on'
  require "simplecov"
  require "simplecov-rcov"
  SimpleCov.formatter = SimpleCov::Formatter::RcovFormatter
  SimpleCov.start "rails"
end

ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'turn'

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  fixtures :all
  
  # Add more helper methods to be used by all tests here...
  
  
  # !warning: knows an _awful_ lot about Houston::Observer's implementation!
  # Intended to keep Houston from firing the _actual_ post_receive hooks
  def with_exclusive_observation
    previous_observers = Houston.observer.instance_variable_get(:@observers)
    begin
      Houston.observer.clear!
      yield
    ensure
      Houston.observer.instance_variable_set(:@observers, previous_observers)
    end
  end
  
  def assert_triggered(event_name, message=nil)
    with_exclusive_observation do
      
      event_triggered = false
      Houston.observer.on event_name do
        event_triggered = true
      end
      
      yield
      
      assert event_triggered, ["The test_run:completed event was not triggered", message].compact.join
    end
  end
  
end
