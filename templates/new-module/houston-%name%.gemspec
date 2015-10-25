$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "houston/<%= name %>/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |spec|
  spec.name          = "houston-<%= name %>"
  spec.version       = Houston::<%= camelized %>::VERSION
  spec.authors       = [<%= git_author.inspect %>]
  spec.email         = [<%= git_email.inspect %>]

  spec.summary       = "TODO: Write a short summary, because Rubygems requires one."
  spec.description   = "TODO: Write a longer description or delete this line."
  spec.homepage      = "TODO: Put your gem's website or public repo URL here."

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.require_paths = ["lib"]
<% unless options.skip_test_unit? -%>
  spec.test_files = Dir["test/**/*"]
<% end -%>

  <%= '# ' if options.dev? || options.edge? -%>s.add_dependency "rails"
end
