source "https://rubygems.org"

# Specify your gem's dependencies in houston.gemspec
gemspec

group :development, :test do
  gem "pry"
end

group :test do
  gem "minitest"
  gem "capybara"
  gem "shoulda-context"
  gem "timecop"
  gem "rr"
  gem "webmock", require: "webmock/minitest"
  gem "factory_girl_rails"
  gem "launchy"

  # For Jenkins
  gem "simplecov-json", require: false
  gem "minitest-reporters", require: false
  gem "minitest-reporters-turn_reporter", require: false
end
