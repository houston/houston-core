module Houston
  module Adapters
    module VersionControl
      class NullRepoClass


        # Public API for a VersionControl::Adapter Repo
        # ------------------------------------------------------------------------- #

        def all_commit_times
          []
        end

        def all_commits
          []
        end

        def ancestors
          []
        end

        def ancestors_until(sha, *args)
          []
        end

        def branches
          {}
        end

        def branches_at(sha)
          []
        end

        def branch(name)
          nil
        end

        def commits_between(sha1, sha2)
          []
        end

        def location
          ""
        end

        def native_commit(sha)
          raise Houston::Adapters::VersionControl::CommitNotFound
        end

        def read_file(file_path, options={})
          nil
        end

        def refresh!(async: false)
        end

        def exists?
          false
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
