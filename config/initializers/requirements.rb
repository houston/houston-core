$:.unshift Rails.root.join("lib", "freight_train", "lib").to_s
$:.unshift Rails.root.join("lib", "lail_extensions", "lib").to_s
$:.unshift Rails.root.join("lib", "unfuddle", "lib").to_s

require 'freight_train'
require 'lail/core_extensions'
require 'unfuddle'
require 'grit_patch'
require 'configuration'

# Load configuration
require Rails.root.join('config', 'config.rb').to_s
