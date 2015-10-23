$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "houston/<%= name %>/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "houston-<%= name %>"
  s.version     = Houston::<%= camelized %>::VERSION
  s.authors     = ["TODO: Your name"]
  s.email       = ["TODO: Your email"]
  s.homepage    = "TODO"
  s.summary     = "TODO: Summary of Houston <%= camelized %>."
  s.description = "TODO: Description of Houston <%= camelized %>."

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
<% unless options.skip_test_unit? -%>
  s.test_files = Dir["test/**/*"]
<% end -%>

  <%= '# ' if options.dev? || options.edge? -%>s.add_dependency "rails"
end
