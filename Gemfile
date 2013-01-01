source "http://rubygems.org"

gem 'rails', '3.2.9'
gem 'activerecord-postgres-hstore' # remove when Rails 4.0

# Database
gem 'pg'

# Twitter Bootstrap
gem 'twitter-bootstrap-rails'

# Font Awesome
gem 'font-awesome-rails'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'coffee-rails', '~> 3.2.1'
  gem 'therubyracer' # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  gem 'uglifier', '>= 1.0.3'
end

# Sass is required in production (see layouts/email.html.erb)
gem 'sass-rails',   '~> 3.2.3'

# Javascript
gem 'jquery-rails'
gem 'sugar-rails'
gem 'backbone-rails'
gem 'handlebars_assets'

# Helpers
gem 'addressable', :require => 'addressable/uri'
gem 'bluecloth'
gem 'bundler' # used to parse Gemfiles
gem 'cancan'
gem 'childprocess'
gem 'default_value_for'
gem 'devise',           '>= 2.0.0'
gem 'devise_invitable', '~> 1.0.0'
gem 'faraday'
gem 'foreman'
gem 'googlecharts'
gem 'grit'
gem 'hpricot'
gem 'letter_opener', :git => 'git://github.com/pcg79/letter_opener.git'
gem 'nokogiri'
gem 'premailer' # for inlining CSS in HTML emails
gem 'remotable', '>= 0.2.2', :git => 'git://github.com/boblail/remotable.git'
gem 'resque'
gem 'yajl-ruby', :require => 'yajl/json_gem'
gem 'whenever' # a DSL for writing CRON jobs



# Modules
#
# Here modules are dynamically included in the Gemfile
#
require "./lib/configuration.rb" # Loads Houston's configuration
Houston.config.modules.each do |mod|
  gem *mod.gemspec
end



# Deploy with Capistrano
gem 'capistrano'
gem 'rvm-capistrano'

# Exception notification
gem 'airbrake'

group :development do
  gem 'thin'
end

group :development, :test do
  gem 'minitest'
  gem 'turn', :require => false # for prettier tests
  gem 'pry' # for debugging
  gem 'pry-remote'
end
