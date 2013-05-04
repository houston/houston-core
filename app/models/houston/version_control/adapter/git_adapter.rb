module Houston
  module VersionControl
    module Adapter
      class GitAdapter
        
        class << self
          
          
          
          # Public API for a VersionControl::Adapter
          # ------------------------------------------------------------------------- #
          
          def errors_with_parameters(project, location)
            connect_to_repo!(location.to_s, project.version_control_temp_path)
            {}
          rescue
            Rails.logger.error $!.message
            Rails.logger.error $!.backtrace
            {git_location: ["might not be right. Houston can't seem to connect to it."]}
          end
          
          def build(project, location)
            return Houston::VersionControl::NullRepo if location.blank?
            
            begin
              temp_path = project.version_control_temp_path
              connection = connect_to_repo!(location.to_s, temp_path)
              self::Repo.new(connection, local: (connection.path == temp_path))
            rescue Rugged::RepositoryError, Rugged::OSError
              Houston::VersionControl::NullRepo
            end
          end
          
          def parameters
            [:git_location]
          end
          
          # ------------------------------------------------------------------------- #
          
          
          
          def connect_to_repo!(location, temp_path)
            repo_uri = Addressable::URI.parse(location)
            git_path = get_local_path_to_repo(repo_uri, temp_path)
            Rugged::Repository.new(git_path)
          end
          
          def get_local_path_to_repo(repo_uri, temp_path)
            if repo_uri.absolute?
              clone!(repo_uri, temp_path) unless File.exists?(temp_path)
              pull!(temp_path) if stale?(temp_path)
              temp_path
            else
              repo_uri.to_s
            end
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
             `git --git-dir=#{local_path} remote update`
            end
          end
          
          def stale?(temp_path)
            Time.now - time_of_last_pull(temp_path) > 1.day
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
