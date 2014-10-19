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
          
          def all_commits
            `git --git-dir=#{git_dir} log --all --pretty='%H'`.split(/\n/).uniq
          end
          
          def ancestors(sha, *args)
            ancestor_walker(sha, *args).map(&method(:to_commit))
          end
          
          def ancestors_until(sha, *args)
            commits = []
            ancestor_walker(sha, *args).each do |commit|
              commit = to_commit(commit)
              commits << commit
              return commits if yield commit
            end
            
            raise CommitNotFound, "No matching ancestor of \"#{sha}\" was found"
          end
          
          def branches
            Hash[connection.branches
              .each(:local)
              .map { |branch| [branch.name, branch.target.oid] }]
          end
          
          def branches_at(sha)
            connection.branches
              .each(:local)
              .select { |branch| branch.target.oid.start_with?(sha) }
              .map(&:name)
          end
          
          def commits_between(sha1, sha2)
            sha1 = sha1.sha if sha1.respond_to?(:sha)
            sha2 = sha2.sha if sha2.respond_to?(:sha)
            
            if sha1.nil? or sha1 == Houston::NULL_GIT_COMMIT
              ancestors(sha2, :including_self).reverse
            else
              native_commit(sha1) # ensure that sha1 exists in the repo
              matces_sha = lambda { |commit| commit.sha.start_with?(sha1) }
              ancestors_until(sha2, :including_self, &matces_sha).reverse[1..-1]
            end
          end
          
          def location
            connection.path
          end
          
          def native_commit(sha)
            return NullCommit.new if sha == Houston::NULL_GIT_COMMIT
            normalize_sha!(sha)
            to_commit connection.lookup(sha)
          rescue Rugged::OdbError
            raise CommitNotFound, "\"#{sha}\" is not a commit"
          rescue Rugged::InvalidError
            raise CommitNotFound, "\"#{sha}\" is not a valid commit"
          rescue Rugged::ObjectError
            raise CommitNotFound, "\"#{sha}\" is too short"
          end
          
          def read_file(file_path, options={})
            blob = find_file(file_path, options={})
            blob && blob.content
          end
          
          def refresh!(async: false)
          end
          
          def exists?
            File.exists?(connection.path)
          end
          
          # ------------------------------------------------------------------------- #
          
          
          
          def find_file(file_path, options={})
            commit = options[:commit] || connection.head.target.oid
            head = native_commit(commit).original
            tree = head.tree
            file_path.split("/").each do |segment|
              object = tree[segment]
              return nil unless object
              tree = connection.lookup object[:oid]
            end
            tree
          rescue Rugged::OdbError
            raise FileNotFound, "\"#{file_path}\" is not in this repo"
          end
          
          def to_s
            location
          end
          
          
          
        private
          
          def normalize_sha!(sha)
            return if sha == Houston::NULL_GIT_COMMIT
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
              original: rugged_commit,
              sha: rugged_commit.oid,
              message: rugged_commit.message,
              authored_at: rugged_commit.author[:time],
              author_name: rugged_commit.author[:name],
              author_email: rugged_commit.author[:email],
              committed_at: rugged_commit.committer[:time],
              committer_name: rugged_commit.committer[:name],
              committer_email: rugged_commit.committer[:email]
            })
          end
          
          def ancestor_walker(sha, *args)
            commit = native_commit(sha)
            shas = [sha]
            
            # by default, start with the commit's parent
            shas = commit.original.parents.map(&:oid) unless args.member? :including_self
            
            walker = Rugged::Walker.new(connection)
            shas.each { |sha| walker.push(sha) }
            walker
          end
          
        end
      end
    end
  end
end
