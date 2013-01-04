module Houston
  module VersionControl
    module Adapter
      class GitAdapter
        class Repo
          
          def initialize(connection, options={})
            @connection = connection
            @local = options.fetch(:local, false)
          end
          
          
          
          # Public API for a VersionControl::Adapter Repo
          # ------------------------------------------------------------------------- #
          
          def all_commit_times
            `git --git-dir=#{git_dir} log --all --pretty='%at'`.split(/\n/).uniq
          end
          
          def branches_at(sha)
            refs = `git --git-dir=#{git_dir} show-ref --heads`
            branches_by_sha = Hash[refs.split(/\n/).map { |line|
              sha, ref = line.split
              [File.basename(ref), sha] }]
            branches_by_sha.fetch(sha, [])
          end
          
          def commits_between(sha1, sha2)
            connection
              .commits_between(sha1, sha2)
              .map(&method(:to_commit))
          end
          
          def commits_during(range)
            Grit::Commit
              .find_all(connection, nil, {after: range.begin, before: range.end})
              .uniq { |grit_commit| "#{grit_commit.authored_date}#{grit_commit.author.email}" }
              .map(&method(:to_commit))
          end
          
          def native_commit(sha)
            connection.commit(sha)
          end
          
          def read_file(file_path)
            connection.tree/file_path
          end
          
          def refresh!
            pull! if mirrored?
          end
          
          # ------------------------------------------------------------------------- #
          
          
          
          def git_dir
            connection.path
          end
          
          def mirrored?
            @local
          end
          
          def pull!
            GitAdapter.pull!(connection.path)
          end
          
          def updated_at
            mirrored? ? GitAdapter.time_of_last_pull(git_dir) : Time.now
          end
          
          
          
        private
          
          attr_reader :connection
          
          def to_commit(grit_commit)
            Houston::VersionControl::Commit.new({
              sha: grit_commit.sha,
              message: grit_commit.message,
              date: grit_commit.committed_date,
              author_name: grit_commit.author.name,
              author_email: grit_commit.author.email
            })
          end
          
        end
      end
    end
  end
end
