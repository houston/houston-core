module Houston
  module VersionControl
    module Adapter
      class GitAdapter
        
        class << self
          
          
          
          # Public API for a VersionControl::Adapter
          # ------------------------------------------------------------------------- #
          
          def problems_with_location(repo_location, temp_path=nil)
            connect_to_repo!(repo_location.to_s, temp_path)
            []
          rescue
            ["might not be right. Houston can't seem to connect to it."]
          end
          
          def create_repo(repo_location, temp_path=nil)
            return Houston::VersionControl::NullRepo if repo_location.blank?
            
            begin
              connection = connect_to_repo!(repo_location.to_s, temp_path)
              self::Repo.new(connection, local: (connection.path == temp_path))
            rescue Grit::InvalidGitRepositoryError, Grit::NoSuchPathError
              Houston::VersionControl::NullRepo
            end
          end
          
          # ------------------------------------------------------------------------- #
          
          
          
          def connect_to_repo!(repo_location, temp_path)
            repo_uri = Addressable::URI.parse(repo_location)
            git_path = get_local_path_to_repo(repo_uri, temp_path)
            Grit::Repo.new(git_path)
          end
          
          def get_local_path_to_repo(repo_uri, temp_path)
            if repo_uri.absolute?
              clone!(repo_uri, temp_path) unless File.exists?(temp_path)
              pull!(temp_path) if stale?(temp_path)
              temp_path
            else
              repo_uri
            end
          end
          
          def clone!(origin_uri, temp_path)
            local_path = File.dirname(temp_path)
            target = File.basename(temp_path)
            
            ActiveRecord::Base.benchmark("[git:clone] #{origin_uri} => #{temp_path}") do
              `cd "#{local_path}" && git clone --mirror #{origin_uri} #{target}`
            end
          end
          
          def pull!(local_path)
            ActiveRecord::Base.benchmark("[git:pull] #{local_path}") do
             `cd "#{local_path}" && git remote update`
            end
          end
          
          def stale?(temp_path)
            Time.now - time_of_last_pull(temp_path) > 1.day
          end
          
          def time_of_last_pull(git_dir)
            File.mtime File.join(git_dir, "FETCH_HEAD")
          end
          
        end
        
      end
    end
  end
end
