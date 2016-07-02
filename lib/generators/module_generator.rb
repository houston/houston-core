require "rails"
require "rails/generators"
require "rails/generators/rails/plugin/plugin_generator"
require "bundler/version"
require "houston/version"

module Generators
  class ModuleBuilder < Rails::PluginBuilder

    def app
      directory "app"
      empty_directory_with_keep_file "app/assets/images/houston/#{name}"
    end

    def config
      template "config/initializers/add_navigation_renderer.rb"
      template "config/database.yml"
      template "config/routes.rb"
      empty_directory_with_keep_file "db"
    end

    def lib
      template "lib/houston/%name%.rb"
      template "lib/houston/%name%/configuration.rb"
      template "lib/houston/%name%/engine.rb"
      template "lib/houston/%name%/railtie.rb"
      template "lib/houston/%name%/version.rb"
      template "lib/houston-%name%.rb"
      template "lib/tasks/%name%_tasks.rake"
    end

    def gemspec
      template "houston-%name%.gemspec"
    end

    def stylesheets
      # do nothing
    end

    def javascripts
      # do nothing
    end

    def readme
      template "README.md"
    end

    def test
      template "test/test_helper.rb"
      template "test/dummy/houston.rb"
      template "test/fixtures/projects.yml"
      template "test/fixtures/users.yml"
      template "test/unit/fixtures_test.rb"
      template "test/acceptance/houston_dummy_test.rb"
    end

  end

  class ModuleGenerator < Rails::Generators::PluginGenerator
    source_root File.expand_path("../../templates/new-module", File.dirname(__FILE__))

    alias_method :module_name, :app_path

    def name
      module_name
    end

    def app_path
      "houston-#{name}"
    end

    # This is what `valid_const?` tests for validity
    def original_name
      module_name
    end

    def get_builder_class
      ModuleBuilder
    end

    def git_author
      `git config user.name`.chomp
    end

    def git_email
      `git config user.email`.chomp
    end

    def full?
      true
    end

    def mountable?
      true
    end

    def engine?
      true
    end

    def with_dummy_app?
      false
    end

    def update_gemfile
      super
      git_init
    end

  protected

    def git_init
      say_status :run, "git init"
      output = `git init .`
      print output unless options[:quiet]
    end

  end
end
