# This file is used by Rack-based servers to start the application.

$HOUSTON_PROCESS_TYPE = :websocket_server

# Load and configure Houston
require_relative "../config/main"

# Initialize the Rails application
# According to the docs (http://edgeguides.rubyonrails.org/action_cable_overview.html#standalone)
# this line should be `Rails.application.eager_load!` but that results in
# strange errors with Houston::Adaptes::VersionControl::GitAdapter.
# This might be overkill, but it works:
Rails.application.initialize!

# Run the ActionCable server
run ActionCable.server
