Dir["#{Rails.root}/app/models/houston/version_control/adapter/*_adapter.rb"].each(&method(:require_dependency))
require_dependency "houston/version_control/errors"

module Houston
  
  # Classes in this namespace are assumed to implement
  # Houston's VersionControl API.
  # 
  # At this time there are a Null adapter (None) and an adapter for use
  # with Git. Adapters for other version control systems can be added here
  # and will be automatically available to Houston projects.
  #
  # VersionControl::Adapter classes are expected to respond to:
  #
  #   - `errors_with_parameters`:
  #       Accepts `version_control_location` and `version_control_temp_path`.
  #       Returns an array of validation messages describing problems with
  #       the value of `version_control_location`. If there are no problems,
  #       the result is an empty array.
  #
  #   - `build`:
  #       Accepts `version_control_location` and `version_control_temp_path`.
  #       Returns an instance of a VersionControl class.
  #       If `version_control_location` is invalid, the class should
  #       return Houston::VersionControl::NullRepo.
  #
  # VersionControl::Adapter instances are expected to respond to:
  #
  #   - `all_commit_times`:
  #       returns the timestamps of every commit made to this project.
  #
  #   - `commits_between`:
  #       accepts two SHAs and returns an array of commits that were made
  #       between those two.
  #
  #   - `native_commit`:
  #       accepts a SHA which identifies a commit and returns a native
  #       commit object.
  #
  #   - `read_file`:
  #       accepts a string representating the path of a file within the
  #       project's repo and returns the contents of that file.
  #
  #   - `refresh!`:
  #       fetches commits from the remote repo only if this repo is a mirror.
  #
  module VersionControl
    
    def self.adapters
      @adapters ||= 
        Adapter.constants
          .map { |sym| sym[/^.*(?=Adapter)/] }
          .sort_by { |name| name == "None" ? "" : name }
    end
    
    def self.adapter(name)
      Adapter.const_get(name + "Adapter")
    end
    
  end
end
