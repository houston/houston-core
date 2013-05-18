module Houston
  module Adapters
    module VersionControl
      class GitAdapter
        class Repo
          
          
          def initialize(connection, location)
            @connection = connection
            @location = location
          end
          
          
          
          def github?
            /github/ === location
          end
          
          def github_project_url
            return "" unless github?
            connection.path.gsub(/^git@(?:www\.)?github.com:/, "https://github.com/").gsub(/^git:/, "https:").gsub(/\.git$/, "")
          end

          def github_commit_url(sha)
            return "" unless github?
            "#{github_project_url}/commit/#{sha}"
          end

          def github_commit_range_url(sha0, sha1)
            return "" unless github?
            "#{github_project_url}/compare/#{sha0}...#{sha1}"
          end
          
          
          
          # Public API for a VersionControl::Adapter Repo
          # ------------------------------------------------------------------------- #
          
          attr_reader :location
          
          def all_commit_times
            `git --git-dir=#{git_dir} log --all --pretty='%at'`.split(/\n/).uniq
          end
          
          def branches_at(sha)
            Rugged::Branch.each(connection, :local)
              .select { |branch| branch.tip.oid.start_with?(sha) }
              .map(&:name)
          end
          
          def commits_between(sha1, sha2)
            pull_and_retry(1) do
              
              # Assert the presence of both commits
              native_commit(sha1)
              native_commit(sha2)
              
              found = false
              walker = connection.walk(sha2)
              commits = walker.take_until { |commit| found = commit.oid.start_with?(sha1) }
              
              raise CommitNotFound, "\"#{sha1}\" is not an ancestor of \"#{sha2}\"" unless found
              
              commits.map(&method(:to_commit))
            end
          end
          
          def native_commit(sha)
            normalize_sha!(sha)
            pull_and_retry(1) do
              connection.lookup(sha)
            end
          rescue CommitNotFound
            $!.message = "\"#{sha}\" is not a commit"
            raise
          end
          
          def read_file(file_path, options={})
            commit = options[:commit] || connection.head.target
            head = native_commit(commit)
            tree = head.tree
            file_path.split("/").each do |segment|
              object = tree[segment]
              return nil unless object
              tree = connection.lookup object[:oid]
            end
            tree.content
          end
          
          def refresh!
            pull! if mirrored?
          end
          
          # ------------------------------------------------------------------------- #
          
          
          
        private
          
          def normalize_sha!(sha)
            sha.strip!
            sha.slice!(40)
            validate_sha!(sha)
          end
          
          def validate_sha!(sha)
            unless sha =~ /^[0-9a-f]+$/i
              raise InvalidShaError, "\"#{sha}\" is not a valid SHA"
            end
          end
          
          def git_dir
            connection.path.chomp("/")
          end
          
          def mirrored?
            Addressable::URI.parse(location).absolute?
          end
          
          def pull_and_retry(retries)
            begin
              yield
            rescue Rugged::OdbError
              if retries > 0
                retries -= 1
                pull!
                retry
              else
                raise Houston::Adapters::VersionControl::CommitNotFound.new($!)
              end
            rescue Rugged::InvalidError
              raise Houston::Adapters::VersionControl::CommitNotFound.new($!)
            end
          end
          
          def pull!
            GitAdapter.pull!(connection.path)
          end
          
          def updated_at
            mirrored? ? GitAdapter.time_of_last_pull(git_dir) : Time.now
          end
          
          attr_reader :connection
          
          def to_commit(rugged_commit)
            Houston::Adapters::VersionControl::Commit.new({
              sha: rugged_commit.oid,
              message: rugged_commit.message,
              date: rugged_commit.author[:time],
              author_name: rugged_commit.author[:name],
              author_email: rugged_commit.author[:email]
            })
          end
          
        end
      end
    end
  end
end
