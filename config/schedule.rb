# Desired cron jobs are defined in Houston's
# global configuration file: config/config.rb
#
# The whenever binary parses Whenever's DSL by
# piping the contents of this file into `instance_eval`.
#
# We use that to our advantage here by loading
# Houston's configuration and instance_evaling
# its cron block here.

original_dir = Dir.pwd
begin
  Dir.chdir File.expand_path(File.join(File.dirname(__FILE__), "..")) # Rails.root
  require "./lib/configuration.rb" # Loads Houston's configuration
  whenever_configuration = Houston.config.cron
  instance_eval(&whenever_configuration) if whenever_configuration
ensure
  Dir.chdir original_dir
end
