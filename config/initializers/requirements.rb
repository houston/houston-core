$:.unshift Rails.root.join("lib", "freight_train", "lib").to_s

require "freight_train"
require "core_ext/duration"
require "parallel_enumerable"
require "unexpected_response"
require "idioms/active_record/insert_many"
require "idioms/active_record/pluck_in_batches"
