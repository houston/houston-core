source "https://rubygems.org"

# Specify your gem's dependencies in houston.gemspec
gemspec

# See https://github.com/sstephenson/execjs#readme for more supported runtimes
gem "therubyracer", platforms: :ruby



# Tooling
gem "airbrake"
gem "sucker_punch" # for Airbrake
gem "skylight"



# Modules
#
# Here modules are dynamically included in the Gemfile
#
root = File.dirname(__FILE__)
root = "./#{root}" unless root.start_with?("/")
require File.join(root, "lib/configuration.rb") # Loads Houston's configuration
Houston.config.gems.each do |gemspec|
  gem *gemspec
end



group :development do
  gem "unicorn-rails"
  gem "letter_opener"
  gem "spring"
  
  # Better error messages
  gem "better_errors"
  gem "meta_request"
end

group :development, :test do
  gem "pry" # for debugging
end

group :test do
  gem "minitest"
  gem "capybara"
  gem "shoulda-context"
  gem "timecop"
  gem "rr"
  gem "webmock", require: "webmock/minitest"
  gem "factory_girl_rails"
  
  # For Jenkins
  gem "simplecov-json", require: false
  gem "minitest-reporters", require: false
  gem "minitest-reporters-turn_reporter", require: false
end
