$:.unshift Rails.root.join("lib", "freight_train", "lib").to_s
$:.unshift Rails.root.join("lib", "lail_extensions", "lib").to_s

require "freight_train"
require "lail/core_extensions"
require "parallel_enumerable"
require "unexpected_response"
