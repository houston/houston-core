# This file is used by Rack-based servers to start the application.

$WEB_SERVER = :rack
require ::File.expand_path('../config/environment',  __FILE__)
run Rails.application
