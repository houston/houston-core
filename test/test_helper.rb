if ENV["COVERAGE"] == "on"
  require "simplecov"
  require "simplecov-json"
  SimpleCov.formatter = SimpleCov::Formatter::JSONFormatter
  SimpleCov.start "rails"
end

ENV["RAILS_ENV"] ||= "test"
require File.expand_path("../../config/environment", __FILE__)
require "rails/test_help"
require "support/houston/adapters/version_control/mock_adapter"
require "capybara/rails"

if ENV["CI"] == "true"
  require "minitest/reporters"
  MiniTest::Reporters.use! [MiniTest::Reporters::DefaultReporter.new,
                            MiniTest::Reporters::JUnitReporter.new]
else
  require "minitest/reporters/turn_reporter"
  MiniTest::Reporters.use! Minitest::Reporters::TurnReporter.new
end



Houston.observer.async = false



class CollectingSender
  attr_reader :collected
  
  def initialize
    @collected = []
  end
  
  def send_to_airbrake(data)
    @collected << data
  end
end

Airbrake.sender = CollectingSender.new
Airbrake.configuration.development_environments = []
Airbrake.configuration.async = false



class ActiveSupport::TestCase
  ActiveRecord::Migration.check_pending!
  include FactoryGirl::Syntax::Methods

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
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
      
      assert event_triggered, ["The event \"#{event_name}\" was not triggered", message].compact.join
    end
  end
  
  def assert_not_triggered(event_name, message=nil)
    with_exclusive_observation do
      
      event_triggered = false
      Houston.observer.on event_name do
        event_triggered = true
      end
      
      yield
      
      refute event_triggered, ["The event \"#{event_name}\" was triggered", message].compact.join
    end
  end
  
  
  
  def assert_deep_equal(expected_value, actual_value)
    differences = differences_between_values(expected_value, actual_value)
    assert differences.none?, differences.join("\n")
  end
  
  def differences_between_values(expected_value, actual_value, context=[])
    if expected_value.is_a?(Float) && actual_value.is_a?(Float)
      differences_between_floats(expected_value, actual_value, context)
    elsif expected_value.is_a?(Array) && actual_value.is_a?(Array)
      differences_between_arrays(expected_value, actual_value, context)
    elsif expected_value.is_a?(Hash) && actual_value.is_a?(Hash)
      differences_between_hashes(expected_value, actual_value, context)
    else
      if expected_value == actual_value
        []
      else
        ["Expected value#{format_context(context)} to be #{expected_value.inspect} but was #{actual_value.inspect}"]
      end
    end
  end
  
  def differences_between_floats(expected_float, actual_float, context=[])
    if (expected_float - actual_float).abs < 0.001
      []
    else
      ["Expected value#{format_context(context)} to be #{expected_float.inspect} but was #{actual_float.inspect}"]
    end
  end
  
  def differences_between_arrays(expected_array, actual_array, context=[])
    if expected_array.length != actual_array.length
      return ["Expected value#{format_context(context)} to be an array with #{expected_array.length} values, but has #{actual_array.length} values"]
    end
    
    differences = []
    expected_array.each_with_index do |expected_value, i|
      actual_value = actual_array[i]
      differences.concat differences_between_values(expected_value, actual_value, context.dup.push(i))
    end
    
    differences
  end
  
  def differences_between_hashes(expected_hash, actual_hash, context=[])
    differences = []
    
    missing_keys = expected_hash.keys - actual_hash.keys
    if missing_keys.any?
      differences << "Expected value#{format_context(context)} to have keys #{missing_keys.inspect}, but is missing them"
    end
    
    extra_keys = actual_hash.keys - expected_hash.keys
    if extra_keys.any?
      differences << "Expected value#{format_context(context)} has keys #{extra_keys.inspect}, but is not expected to have them"
    end
    
    shared_keys = expected_hash.keys & actual_hash.keys
    shared_keys.each do |key|
      expected_value = expected_hash[key]
      actual_value = actual_hash[key]
      differences.concat differences_between_values(expected_value, actual_value, context.dup.push(key))
    end
    
    differences
  end
  
  def format_context(context)
    return "" if context.none?
    path = context.shift.to_s
    context.each do |segment|
      path << "[#{segment.inspect}]"
    end
    " of #{path}"
  end
  
  
end



class ActionController::TestCase
  include Devise::TestHelpers
  
end
