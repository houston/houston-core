require_relative "boot"

require "rails/all"
require "houston/boot"

# Require gems listed in gemspec
require "activerecord-import"
require "addressable/uri"
require "browser"
require "cancan"
require "concurrent"
require "devise"
require "devise_invitable"
require "faraday"
require "faraday-http-cache"
require "faraday-raise-errors"
require "gemoji"
require "handlebars_assets"
require "neat-rails"
require "nokogiri"
require "oauth2"
require "oj"
require "openxml/xlsx"
require "premailer"
require "progressbar"
require "rack/utf8_sanitizer"
require "kramdown"
require "slackdown"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

require "coffee_script"
require "uglifier"

require "houston/params_serializer"

module Houston
  def self.host=(value)
    @host = value
  end

  def self.host
    return @host if defined?(@host)
    Houston.config.host
  end

  def self.root_url
    protocol = "http"
    protocol = "https" if Houston.config.use_ssl?
    "#{protocol}://#{host}"
  end

  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.0

    # This Rails application gets initialized different ways: many times it is
    # intialized from within a Houston instance project. This line ensures that
    # Rails.root always points to _this_ project. (Houston.root may differ.)
    config.root = File.expand_path("../../", __FILE__)

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Use SQL instead of Active Record's schema dumper when creating the database.
    # This is necessary if your schema can't be completely dumped by the schema dumper,
    # like if you have constraints or database-specific column types
    config.active_record.schema_format = :sql

    # Automatically compress responses that accept gzip encoding
    config.middleware.use Rack::Deflater

    # Support the oEmbed protocol
    require "rack/oembed"
    config.middleware.use Rack::Oembed, path: "oembed/1.0"

    # Respond with a 400 when requests are malformed
    # http://stackoverflow.com/a/24727310/731300
    config.middleware.insert 0, Rack::UTF8Sanitizer

    # Log the type of process that Houston is running in
    config.before_initialize do
      message = "\e[94mHouston is running as a \e[4m#{Houston.running_as.to_s.titleize}\e[0m"
      puts message if Rails.env.development?
      Rails.logger.debug message
    end

    def load_seed
      seed_file = Houston.root.join("db/seeds.rb")
      load(seed_file) if seed_file.exist?
    end

  end
end
