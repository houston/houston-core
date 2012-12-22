module Houston
  module VersionControl
    class NullRepoClass
      
      
      # Public API for a VersionControl::Adapter Repo
      # ------------------------------------------------------------------------- #
      
      def all_commit_times
        []
      end
      
      def commits_between(sha1, sha2)
        []
      end
      
      def commits_during(range)
        []
      end
      
      def native_commit(sha)
        nil
      end
      
      def read_file(file_path)
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
