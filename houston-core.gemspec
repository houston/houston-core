# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "houston/version"

Gem::Specification.new do |spec|
  spec.name          = "houston-core"
  spec.version       = Houston::VERSION
  spec.authors       = ["Bob Lail"]
  spec.email         = ["bob.lailfamily@gmail.com"]

  spec.summary       = %q{Mission Control for your projects and teams}
  spec.homepage      = "https://github.com/houston/houston-core"

  spec.files         = `git ls-files -z`.split("\x0").reject { |file|
    file =~ /^script\//
    file =~ /^support\//
  }
  spec.executables   = ["houston"]
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]



  # For Houston as a Web Application
  spec.add_dependency "rails", "~> 5.0.0"
  spec.add_dependency "pg", "~> 0.19.0"
  # --------------------------------
  spec.add_dependency "activerecord-import"
  spec.add_dependency "activerecord-pluck_in_batches", "~> 0.2.0"
  spec.add_dependency "addressable", "~> 2.3.8"
  spec.add_dependency "attentive", ">= 0.3.6"
  spec.add_dependency "browser", "~> 2.3.0"
  spec.add_dependency "cancancan", "~> 1.16.0"
  spec.add_dependency "concurrent-ruby", "~> 1.0.2"
  spec.add_dependency "devise"
  spec.add_dependency "devise_invitable"
  spec.add_dependency "faraday", "~> 0.9.2"
  spec.add_dependency "faraday-http-cache", "~> 1.2.2"
  spec.add_dependency "faraday-raise-errors", "~> 0.2.0"
  spec.add_dependency "gemoji", "~> 2.1.0"
  spec.add_dependency "handlebars_assets", "~> 0.23.0"
  spec.add_dependency "neat-rails"
  spec.add_dependency "nokogiri"
  spec.add_dependency "oauth2"
  spec.add_dependency "oj", "~> 2.18"
  spec.add_dependency "openxml-xlsx", ">= 0.2.0"
  spec.add_dependency "pg_search", "~> 1.0.5"
  spec.add_dependency "premailer", "~> 1.8.6"
  spec.add_dependency "progressbar", "~> 0.21.0" # for long migrations
  spec.add_dependency "rack-utf8_sanitizer", "~> 1.3.1"
  spec.add_dependency "thor"
  spec.add_dependency "houston-vestal_versions"

  # For parsing Markdown
  spec.add_dependency "kramdown"
  spec.add_dependency "slackdown", ">= 0.2.1"

  # The Asset Pipeline
  spec.add_dependency "sass-rails", "~> 5.0"
  spec.add_dependency "uglifier", ">= 2.7.2"
  spec.add_dependency "coffee-rails", "~> 4.1.0"

  # Houston's background jobs daemon
  spec.add_dependency "rufus-scheduler", "~> 3.3.4"

  # Used to edit releases' changes and teams' roles
  spec.add_dependency "nested_editor_for"

end
