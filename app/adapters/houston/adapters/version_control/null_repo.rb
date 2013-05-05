module Houston
  module Adapters
    module VersionControl
      class NullRepoClass
        
        
        # Public API for a VersionControl::Adapter Repo
        # ------------------------------------------------------------------------- #
        
        def all_commit_times
          []
        end
        
        def branches_at(sha)
          []
        end
        
        def commits_between(sha1, sha2)
          []
        end
        
        def native_commit(sha)
          nil
        end
        
        def read_file(file_path, options={})
          nil
        end
        
        def refresh!
        end
        
        # ------------------------------------------------------------------------- #
        
        
        def nil?
          true
        end
        
      end
      
      NullRepo = NullRepoClass.new
    end
  end
end
