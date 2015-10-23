# This file is used by Rack-based servers to start the application.

$WEB_SERVER = :rack

# Load and configure Houston
require_relative "config/main"

# Initialize the Rails application
Rails.application.initialize!

# Run the application
run Rails.application
