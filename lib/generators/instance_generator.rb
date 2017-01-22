require "rails"
require "rails/generators"
require "rails/generators/app_base"
require "houston/version"

module Generators
  class InstanceGenerator < Rails::Generators::AppBase
    source_root File.expand_path("../../templates/new-instance", File.dirname(__FILE__))

    argument :app_path, type: :string

    def copy_files
      copy_file ".gitignore", "#{app_path}/.gitignore"

      path = source_paths[0]
      path_length = path.length + 1
      Dir.glob(path + "/**/*").each do |file|
        next if File.directory?(file)
        path = file[path_length..-1]
        template path, "#{app_path}/#{path}"
      end

      File.chmod 0755, "#{app_path}/bin/rails"
      File.chmod 0755, "#{app_path}/bin/setup"

      empty_directory_with_keep_file "#{app_path}/tmp/pids"
    end

  end
end
