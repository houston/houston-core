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
          rescue
            Rails.logger.error $!.message
            Rails.logger.error $!.backtrace
            {git_location: ["might not be right. Houston can't seem to connect to it."]}
          end
          
          def build(project, location)
            location = Addressable::URI.parse(location.to_s)
            return Houston::Adapters::VersionControl::NullRepo if location.blank?
            
            begin
              connection = connect_to_repo!(location, project.version_control_temp_path)
              
              return self::Repo.new(connection) unless location.absolute?
              return self::GithubRepo.new(connection, location) if /github/ === location
              return self::RemoteRepo.new(connection, location)
            rescue Rugged::RepositoryError, Rugged::OSError
              Houston::Adapters::VersionControl::NullRepo
            end
          end
          
          def parameters
            [:git_location]
          end
          
          # ------------------------------------------------------------------------- #
          
          
          
          def connect_to_repo!(repo_uri, temp_path)
            git_path = get_local_path_to_repo(repo_uri, temp_path)
            Rugged::Repository.new(git_path)
          end
          
          def get_local_path_to_repo(repo_uri, temp_path)
            if repo_uri.absolute?
              clone!(origin_uri, temp_path) unless File.exists?(temp_path)
              temp_path
            else
              repo_uri.to_s
            end
          end
          
          def sync!(origin, local_path)
            File.exists?(local_path) ? pull!(local_path) : clone!(origin, local_path)
          end
          
          def clone!(origin_uri, temp_path)
            local_path = File.dirname(temp_path)
            target = File.basename(temp_path)
            
            ActiveRecord::Base.benchmark("[git:clone] #{origin_uri} => #{temp_path}") do
              `cd #{local_path} && git clone --mirror #{origin_uri} #{target}`
            end
          end
          
          def pull!(local_path)
            ActiveRecord::Base.benchmark("[git:pull] #{local_path}") do
             `git --git-dir=#{local_path} remote update --prune`
            end
          end
          
          def time_of_last_pull(git_dir)
            fetch_head = File.join(git_dir, "FETCH_HEAD")
            return 100.years.ago unless File.exists?(fetch_head)
            File.mtime fetch_head
          end
          
        end
        
      end
    end
  end
end
