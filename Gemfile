source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails"
gem "rails", "~> 4.1.0"

gem "pg"

gem "addressable", :require => "addressable/uri"
gem "bundler" # used to parse Gemfiles
gem "cancan"
gem "childprocess"
gem "codeclimate-test-reporter", "0.2.0"
gem "default_value_for"
gem "devise", "~> 3.0.0"
gem "devise_invitable"
gem "devise_ldap_authenticatable", :git => "https://github.com/houstonmc/devise_ldap_authenticatable.git"
gem "faraday"
gem "faraday-http-cache"
gem "gemoji"
gem "gemnasium"
gem "googlecharts"
gem "hpricot"
gem "nokogiri"
gem "oauth-plugin", "~> 0.5.1"
gem "octokit" # for adapting to GitHub Issues
gem "oj"
gem "premailer", "1.7.3" # for inlining CSS in HTML emails
gem "progressbar" # for long migrations
gem "redcarpet"
gem "rugged" # for speaking to Git
gem "simplecov"
gem "strongbox" # for encrypting user credentials
gem "sucker_punch" # for Airbrake
gem "unfuddle", github: "boblail/unfuddle", branch: "master"
gem "whenever" # a DSL for writing CRON jobs

gem "backbone-rails", "~> 1.0.0"
gem "handlebars_assets", "0.8.2"
gem "jquery-rails", "2.2.1"
gem "sugar-rails"
gem "twitter-bootstrap-rails", "2.2.6"
gem "less-rails", "2.3.2" # for Twitter Bootstrap

# Tooling
gem "airbrake", "~> 3.1.15" # exception notification
gem "skylight"



# Modules
#
# Here modules are dynamically included in the Gemfile
#
require "./lib/configuration.rb" # Loads Houston"s configuration
Houston.config.modules.each do |mod|
  gem *mod.gemspec
end



# Use SCSS for stylesheets
gem "sass-rails", "~> 4.0.0"

# Use Uglifier as compressor for JavaScript assets
gem "uglifier", ">= 1.3.0"

# Use CoffeeScript for .js.coffee assets and views
gem "coffee-rails", "~> 4.0.0"

# See https://github.com/sstephenson/execjs#readme for more supported runtimes
gem "therubyracer", platforms: :ruby

group :development do
  gem "unicorn-rails"
  gem "letter_opener"
  gem "spring"
  # gem "rack-mini-profiler"
  
  # Better error messages
  gem "better_errors"
  gem "meta_request"
end

group :development, :test do
  gem "pry" # for debugging
end

group :test do
  gem "minitest"
  gem "idioms", github: "concordia-publishing-house/idioms", branch: "master"
  gem "capybara"
  gem "shoulda-context"
  gem "timecop"
  gem "rr"
  gem "webmock", require: "webmock/minitest"
  
  # For Jenkins
  gem "simplecov-json", :require => false, :git => "git://github.com/houstonmc/simplecov-json.git"
  gem "minitest-reporters", require: false
end
