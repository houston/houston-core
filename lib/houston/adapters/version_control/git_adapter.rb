require "houston/adapters/version_control/git_adapter/repo"
require "houston/adapters/version_control/git_adapter/remote_repo"
require "houston/adapters/version_control/git_adapter/github_repo"

module Houston
  module Adapters
    module VersionControl
      class GitAdapter
        class << self



          # Public API for a VersionControl::Adapter
          # ------------------------------------------------------------------------- #

          def errors_with_parameters(project, location)
            location = location.to_s
            return ERROR_BLANK if location.blank?

            if local_path? location
              return ERROR_DOES_NOT_EXIST unless File.exists? location
            else
              return ERROR_CANT_CONNECT unless can_fetch? location
            end

            {}
          end

          def build(project, location)
            connect location, project.version_control_temp_path
          end

          def connect(location, temp_path)
            location = location.to_s
            return Houston::Adapters::VersionControl::NullRepo if location.blank?

            if local_path? location
              return Houston::Adapters::VersionControl::NullRepo unless File.exists? location

              return self::Repo.new(location)
            else
              return Houston::Adapters::VersionControl::NullRepo unless File.exists?(temp_path) || can_fetch?(location)

              return self::GithubRepo.new(temp_path, location) if /github/ === location
              return self::RemoteRepo.new(temp_path, location)
            end
          end

          def parameters
            %w{git.location}
          end

          # ------------------------------------------------------------------------- #



          def credentials
            Rugged::Credentials::SshKey.new(
              username: SSH_USERNAME,
              privatekey: SSH_PRIVATEKEY,
              publickey: SSH_PUBLICKEY)
          end



        private

          ERROR_BLANK = {"git.location" => ["is blank"]}.freeze
          ERROR_DOES_NOT_EXIST = {"git.location" => ["does not exist"]}.freeze
          ERROR_CANT_CONNECT = {"git.location" => ["might not be right. Houston can't seem to connect to it."]}.freeze

          SSH_USERNAME = "git".freeze
          SSH_PRIVATEKEY = File.expand_path("~/.ssh/id_rsa").freeze
          SSH_PUBLICKEY = File.expand_path("~/.ssh/id_rsa.pub").freeze

          def local_path?(location)
            !Addressable::URI.parse(location.to_s).absolute?
          end

          def can_fetch?(url)
            Houston.benchmark "[git_adapter] can_fetch?(#{url})" do
              Dir.mktmpdir do |path|
                repo = Rugged::Repository.init_at path, :bare
                remote = repo.remotes.create_anonymous(url)
                remote.check_connection(:fetch, credentials: GitAdapter.credentials)
              end
            end
          end

        end
      end
    end
  end
end
