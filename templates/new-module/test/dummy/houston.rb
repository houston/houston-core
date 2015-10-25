# Load Houston
require "houston/application"

# Configure Houston
Houston.config do

  # Houston should load config/database.yml from this module
  # rather than from Houston Core.
  root Pathname.new File.expand_path("../../..",  __FILE__)

  # Give dummy values to these required fields.
  host "houston.test.com"
  mailer_sender "houston@test.com"

  # Houston still hard-codes knowledge of these Roles.
  # This will eventually be refactored away.
  roles "Developer", "Tester"
  project_roles "Maintainer"

  # Mount this module on the dummy Houston application.
  use :<%= name %>

end
