# This file is used by Rack-based servers to start the application.

$HOUSTON_PROCESS_TYPE = :web_server

# Load and configure Houston
require_relative "config/main"

# Initialize the Rails application
Rails.application.initialize!

# Run the application
run Rails.application
