module Houston
  module Adapters
    module VersionControl
      class GitAdapter
        class Repo
          
          
          def initialize(connection)
            @connection = connection
          end
          
          
          
          # Public API for a VersionControl::Adapter Repo
          # ------------------------------------------------------------------------- #
          
          def all_commit_times
            `git --git-dir=#{git_dir} log --all --pretty='%at'`.split(/\n/).uniq
          end
          
          def ancestors(sha)
            native_commit(sha)
            walker = connection.walk(sha)
            walker.next # don't start with the commit itself, start with its parent
            
            walker.map(&method(:to_commit))
          end
          
          def ancestors_until(sha, *args)
            # Assert the presence of the commit
            native_commit(sha)
            
            walker = connection.walk(sha)
            
            # by default, start with the commit's parent
            walker.next unless args.member? :including_self
            
            commits = []
            walker.each do |commit|
              commit = to_commit(commit)
              commits << commit
              return commits if yield commit
            end
            
            raise CommitNotFound, "No matching ancestor of \"#{sha}\" was found"
          end
          
          def branches_at(sha)
            Rugged::Branch.each(connection, :local)
              .select { |branch| branch.tip.oid.start_with?(sha) }
              .map(&:name)
          end
          
          def commits_between(sha1, sha2)
            native_commit(sha1)
            matces_sha = lambda { |commit| commit.sha.start_with?(sha1) }
            ancestors_until(sha2, :including_self, &matces_sha).reverse[1..-1]
          end
          
          def location
            connection.path
          end
          
          def native_commit(sha)
            normalize_sha!(sha)
            connection.lookup(sha)
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
