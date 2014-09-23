module Houston
  module Adapters
    module VersionControl
      class GitAdapter
        class << self
          
          
          
          # Public API for a VersionControl::Adapter
          # ------------------------------------------------------------------------- #
          
          def errors_with_parameters(project, location)
            location = Addressable::URI.parse(location.to_s)
            connect_to_repo!(location, project.version_control_temp_path)
            {}
          rescue Rugged::RepositoryError, Rugged::OSError
            Rails.logger.error "#{$!.class.name}: #{$!.message}\n  #{$!.backtrace.take(7).join("\n  ")}"
            { git_location: ["might not be right. Houston can't seem to connect to it."] }
          end
          
          def build(project, location)
            connect location, project.version_control_temp_path
          end
          
          def connect(location, temp_path)
            location = Addressable::URI.parse(location.to_s)
            return Houston::Adapters::VersionControl::NullRepo if location.blank?
            
            connection = connect_to_repo! location, temp_path
            
            return self::Repo.new(connection) unless location.absolute?
            return self::GithubRepo.new(connection, location) if /github/ === location
            return self::RemoteRepo.new(connection, location)
          rescue Rugged::RepositoryError, Rugged::OSError
            Houston::Adapters::VersionControl::NullRepo
          end
          
          def parameters
            [:git_location]
          end
          
          # ------------------------------------------------------------------------- #
          
          
          
          def connect_to_repo!(repo_uri, temp_path)
            git_path = get_local_path_to_repo(repo_uri, temp_path.to_s)
            Rugged::Repository.new(git_path)
          end
          
          def get_local_path_to_repo(repo_uri, temp_path)
            if repo_uri.absolute?
              clone!(repo_uri, temp_path) unless File.exists?(temp_path)
              temp_path
            else
              repo_uri.to_s
            end
          end
          
          def clone!(origin_uri, local_path, async: false)
            if async
              Houston.async { _clone!(origin_uri, local_path, true) }
            else
              _clone!(origin_uri, local_path, false)
            end
          end
          
          def credentials
            @credentials ||= Rugged::Credentials::SshKey.new(
              username: "git",
              privatekey: File.expand_path("~/.ssh/id_rsa"),
              publickey: File.expand_path("~/.ssh/id_rsa.pub"))
          end
          
          
          
        private
          
          def _clone!(origin_uri, local_path, async)
            Houston.benchmark("[git:clone#{":async" if async}] #{origin_uri} => #{local_path}") do
              Rugged::Repository.clone_at origin_uri.to_s, local_path.to_s,
                credentials: GitAdapter.credentials,
                bare: true
            end
          end
          
        end
      end
    end
  end
end
