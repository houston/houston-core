# Load Houston
require "houston/application"

# Configure Houston
Houston.config do

  # Houston should load config/database.yml from this module
  # rather than from Houston Core.
  root Pathname.new File.expand_path("../../..",  __FILE__)

  # Give dummy values to these required fields.
  host "houston.test.com"
  secret_key_base "<%= SecureRandom.hex(15) %>"
  mailer_sender "houston@test.com"

  # Mount this module on the dummy Houston application.
  use :<%= name %>

end
