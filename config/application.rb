require File.expand_path("../boot", __FILE__)

require "rails/all"
require_relative "../lib/configuration.rb" # Loads Houston's configuration
require_relative "../lib/houston_server.rb"
require_relative "../lib/houston_daemonize.rb"

# Require gems listed in gemspec
require "activerecord-import"
require "activerecord/insert_many"
require "activerecord/pluck_in_batches"
require "addressable/uri"
require "backbone-rails"
require "cancan"
require "codeclimate-test-reporter"
require "default_value_for"
require "devise"
require "devise_invitable"
require "devise_ldap_authenticatable"
require "faraday"
require "faraday-http-cache"
require "faraday-raise-errors"
require "gemnasium"
require "gemoji"
require "googlecharts"
require "handlebars_assets"
require "hpricot"
require "nested_editor_for"
require "neat-rails"
require "nokogiri"
require "oauth-plugin"
require "octokit"
require "oj"
require "pg_search"
require "premailer"
require "progressbar"
require "rack/utf8_sanitizer"
require "redcarpet"
require "rugged"
require "simplecov"
require "strongbox"
require "sugar-rails"
require "thread_safe"
require "vestal_versions"
require "whenever"
require "xlsx"


# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)


require "coffee_script"
require "uglifier"


module Houston
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
    
    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = "Central Time (US & Canada)"
    
    # Use SQL instead of Active Record's schema dumper when creating the database.
    # This is necessary if your schema can't be completely dumped by the schema dumper,
    # like if you have constraints or database-specific column types
    config.active_record.schema_format = :sql
    
    # Precompile additional assets (application.js, application.css, and all non-JS/CSS are already added)
    config.assets.precompile += %w( print.css )
    
    # While implementing strong parameters!
    config.action_controller.permit_all_parameters = true
    
    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de
    
    # Automatically compress responses that accept gzip encoding
    config.middleware.use Rack::Deflater

    # Respond with a 400 when requests are malformed
    # http://stackoverflow.com/a/24727310/731300
    config.middleware.insert 0, Rack::UTF8Sanitizer
  end
end

Houston.observer.fire "boot"
