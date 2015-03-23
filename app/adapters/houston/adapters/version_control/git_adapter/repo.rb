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
          
          def ancestors(sha, options={})
            ancestor_walker(sha, options).map(&method(:to_commit))
          ensure
            close
          end
          
          def ancestors_until(sha, options={})
            commits = []
            ancestor_walker(sha, options).each do |commit|
              commit = to_commit(commit)
              commits << commit
              return commits if yield commit
            end
            
            raise CommitNotFound, "No matching ancestor of \"#{sha}\" was found"
          ensure
            close
          end
          
          def branches
            Hash[connection.branches
              .each(:local)
              .map { |branch| [branch.name, branch.target.oid] }]
          ensure
            close
          end
          
          def branches_at(sha)
            connection.branches
              .each(:local)
              .select { |branch| branch.target.oid.start_with?(sha) }
              .map(&:name)
          ensure
            close
          end
          
          def commits_between(sha1, sha2)
            sha1 = sha1.sha if sha1.respond_to?(:sha)
            sha2 = sha2.sha if sha2.respond_to?(:sha)
            sha1 = nil if sha1 == Houston::NULL_GIT_COMMIT
            
            ancestors(sha2, including_self: true, hide: sha1).reverse
          end
          
          def location
            connection.path
          end
          
          def native_commit(sha)
            return NullCommit.new if sha == Houston::NULL_GIT_COMMIT
            to_commit find_commit(sha)
          ensure
            close
          end
          
          def read_file(file_path, options={})
            blob = find_file(file_path, options={})
            blob && blob.content
          ensure
            close
          end
          
          def refresh!(async: false)
          end
          
          def exists?
            File.exists?(connection.path)
          end
          
          # ------------------------------------------------------------------------- #
          
          
          
          def find_file(file_path, options={})
            commit = options[:commit] || connection.head.target.oid
            head = find_commit(commit)
            tree = head.tree
            file_path.split("/").each do |segment|
              object = tree[segment]
              return nil unless object
              tree = connection.lookup object[:oid]
            end
            tree
          rescue Rugged::OdbError, Rugged::ReferenceError
            raise FileNotFound, "\"#{file_path}\" is not in the repo #{to_s}"
          ensure
            close
          end
          
          def to_s
            location
          end
          
          def close
            # Before `ancestors` had `ensure close` in it, I tried the following:
            #
            #     members = Project["members"]
            #
            #  a) 5.times { members.repo.ancestors("8db64ad", including_self: true, hide: "50f0046") }
            #  b) 5.times { members.repo.ancestors("8db64ad", including_self: true, hide: "50f0046");
            #               members.repo.send(:connection).close }
            #  c) 5.times { members.repo.ancestors("8db64ad", including_self: true, hide: "50f0046");
            #               GC.start;
            #               members.repo.send(:connection).close }
            #
            # The first two raised exceptions but the last one didn't.
            GC.start
            connection.close
          end
          
          
          
        protected
          
          attr_reader :connection
          
          def find_commit(sha)
            normalize_sha!(sha)
            object = connection.lookup(sha)
            object = object.target if object.is_a? Rugged::Tag::Annotation
            object
          rescue Rugged::OdbError
            raise CommitNotFound, "\"#{sha}\" is not a commit"
          rescue Rugged::InvalidError
            raise CommitNotFound, "\"#{sha}\" is not a valid commit"
          rescue Rugged::ObjectError
            raise CommitNotFound, "\"#{sha}\" is too short"
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
          
          def ancestor_walker(sha, options={})
            commit = find_commit(sha)
            push_shas = [commit.oid]
            
            # by default, start with the commit's parent
            push_shas = commit.parents.map(&:oid) unless options[:including_self]
            hide_shas = Array(options.fetch(:hide, []))
              .map { |sha| find_commit(sha).oid } # ensure that each of these exists in the repo
            
            walker = Rugged::Walker.new(connection)
            push_shas.each { |sha| walker.push(sha) }
            hide_shas.each { |sha| walker.hide(sha) }
            walker
          end
          
        end
      end
    end
  end
end
