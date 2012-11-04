$:.unshift Rails.root.join("lib", "freight_train", "lib").to_s
$:.unshift Rails.root.join("lib", "lail_extensions", "lib").to_s
$:.unshift Rails.root.join("lib", "unfuddle", "lib").to_s

require 'freight_train'
require 'lail/core_extensions'
require 'lail/helpers/flash_message_helper'
require 'unfuddle'
require 'grit_patch'
require 'configuration'
require 'unfuddle_dump'

# Apply Houston configuration
Rails.application.config.action_mailer.smtp_settings = Houston.config.smtp
Unfuddle.config(Houston.config.ticket_system_configuration)
Houston.observer.fire "boot"
