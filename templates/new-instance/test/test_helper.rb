ENV["RAILS_ENV"] ||= "test"

# Load and configure Houston
require_relative "../config/main"

# Initialize the Rails application
Rails.application.initialize!

require "rails/test_help"
