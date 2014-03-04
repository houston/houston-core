source 'http://rubygems.org'

gem 'rails', '~> 3.2.13'
gem 'activerecord-postgres-hstore' # remove when Rails 4.0
gem 'activerecord-postgres-array' # remove when Rails 4.0 and convert 'string_array' in migrations to string :array => true

gem 'pg'

gem 'addressable', :require => 'addressable/uri'
gem 'redcarpet'
gem 'bundler' # used to parse Gemfiles
gem 'cancan'
gem 'childprocess'
gem 'codeclimate-test-reporter', '0.2.0'
gem 'default_value_for'
gem 'devise',           '~> 2.2.3'
gem 'devise_invitable', '~> 1.1.6'
gem 'devise_ldap_authenticatable', :git => 'https://github.com/houstonmc/devise_ldap_authenticatable.git'
gem 'faraday'
gem 'faraday-http-cache'
gem 'gemoji'
gem 'googlecharts'
gem 'hpricot'
gem 'nokogiri'
gem 'oauth-plugin', '~> 0.5.1'
gem 'octokit' # for adapting to GitHub Issues
gem 'oj'
gem 'premailer' # for inlining CSS in HTML emails
gem 'progressbar' # for long migrations
gem 'rugged', '0.17.0.b7' # for speaking to Git
gem 'simplecov'
gem 'strongbox' # for encrypting user credentials
gem 'sucker_punch' # for Airbrake
gem 'unfuddle', github: 'boblail/unfuddle', branch: 'master'
gem 'whenever' # a DSL for writing CRON jobs

gem 'backbone-rails'
gem 'handlebars_assets', '0.8.2'
gem 'jquery-rails'
gem 'sass-rails',   '~> 3.2.3' # Sass is required in production (see layouts/email.html.erb)
gem 'sugar-rails'
gem 'twitter-bootstrap-rails'

# Tooling
gem 'airbrake', '~> 3.1.15' # exception notification
gem 'newrelic_rpm'



# Modules
#
# Here modules are dynamically included in the Gemfile
#
require './lib/configuration.rb' # Loads Houston's configuration
Houston.config.modules.each do |mod|
  gem *mod.gemspec
end



# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'coffee-rails', '~> 3.2.1'
  gem 'therubyracer' # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  gem 'less-rails' # For Twitter Bootstrap
  gem 'uglifier', '>= 1.0.3'
  
  # gem 'turbo-sprockets-rails3', '>= 0.3.6'
end

group :development do
  gem 'unicorn-rails'
  gem 'letter_opener'
  gem 'spring'
  # gem 'rack-mini-profiler'
  
  # Better error messages
  gem 'better_errors'
  gem 'meta_request'
end

group :development, :test do
  gem 'minitest'
  gem 'turn', :require => false # for prettier tests
  gem 'shoulda-context'
  gem 'timecop'
  gem 'rr'
  
  # For Jenkins
  gem 'simplecov-json', :require => false, :git => 'git://github.com/houstonmc/simplecov-json.git'
  gem 'ci_reporter', :require => false
  
  gem 'pry' # for debugging
end
