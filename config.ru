# Local-dev Rack entrypoint for running the houston-core gem source as a Rails
# app. Distributed Houston instances have their own config.ru via the template
# in templates/new-instance/; this file lets us boot the gem repo directly.

$HOUSTON_PROCESS_TYPE = :web_server

require_relative "config/application"
require_relative "config/environment"

run Rails.application
