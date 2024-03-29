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
  spec.add_dependency "rails", "~> 6.0.3"
  spec.add_dependency "pg", "~> 1.2.0"
  # --------------------------------
  spec.add_dependency "activerecord-import"
  spec.add_dependency "addressable"
  spec.add_dependency "attentive", ">= 0.3.9"
  spec.add_dependency "browser", "~> 2.3.0"
  spec.add_dependency "cancancan", ">= 3.0.0"
  spec.add_dependency "concurrent-ruby", "~> 1.0.2"
  spec.add_dependency "devise"
  spec.add_dependency "devise_invitable"
  spec.add_dependency "faraday"
  spec.add_dependency "faraday-http-cache"
  spec.add_dependency "gemoji", "~> 2.1.0"
  spec.add_dependency "handlebars_assets", "~> 0.23.0"
  spec.add_dependency "mail"
  spec.add_dependency "neat-rails", "~> 0.5.1"
  spec.add_dependency "nokogiri", "~> 1.8"
  spec.add_dependency "oauth2"
  spec.add_dependency "oj", "~> 3.0"
  spec.add_dependency "openxml-xlsx", ">= 0.2.0"
  spec.add_dependency "pg_search"
  spec.add_dependency "premailer", "~> 1.10.0"
  spec.add_dependency "progressbar", "~> 0.21.0" # for long migrations
  spec.add_dependency "rack-utf8_sanitizer", "~> 1.3.1"
  spec.add_dependency "thor"

  # For parsing Markdown
  spec.add_dependency "kramdown"
  spec.add_dependency "slackdown", ">= 0.2.1"

  # The Asset Pipeline
  spec.add_dependency "sass-rails", "~> 6.0"
  spec.add_dependency "uglifier", ">= 2.7.2"
  spec.add_dependency "coffee-rails"

  # Houston's background jobs daemon
  spec.add_dependency "rufus-scheduler", "~> 3.4.0"

end
