require "houston/adapters/version_control/git_adapter/diff_changes"
require "houston/adapters/version_control/null_commit"

module Houston
  module Adapters
    module VersionControl
      class GitAdapter
        class Repo
          attr_reader :location



          def initialize(location)
            @location = location.to_s
            @branch_location = :local
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
            ancestor_walker(sha, options, &method(:to_commit))
          end

          def ancestors_until(sha, options={})
            commits = []
            ancestor_walker(sha, options) do |commit|
              commit = to_commit(commit)
              commits << commit
              return commits if yield commit
            end

            raise CommitNotFound, "No matching ancestor of \"#{sha}\" was found"
          end

          def branches
            Hash[connection.branches
              .each(branch_location)
              .map { |branch| [name_of_branch(branch), branch.target.oid] }]
          ensure
            release
          end

          def branches_at(sha)
            connection.branches
              .each(branch_location)
              .select { |branch| branch.target.oid.start_with?(sha) }
              .map { |branch| name_of_branch(branch) }
          ensure
            release
          end

          def commits_between(sha1, sha2)
            sha1 = sha1.sha if sha1.respond_to?(:sha)
            sha2 = sha2.sha if sha2.respond_to?(:sha)
            sha1 = nil if sha1 == Houston::NULL_GIT_COMMIT

            ancestors(sha2, including_self: true, hide: sha1).reverse

          rescue
            $!.additional_information[:repo] = to_s
            $!.additional_information[:commit_range] = "#{sha1}...#{sha2}"
            raise
          end

          def native_commit(sha)
            return NullCommit.new if sha == Houston::NULL_GIT_COMMIT
            to_commit find_commit(sha)
          ensure
            release
          end

          def read_file(file_path, options={})
            blob = find_file(file_path, options={})
            blob && blob.content
          ensure
            release
          end

          def refresh!(async: false)
          end

          def exists?
            File.exists?(git_path)
          end

          # ------------------------------------------------------------------------- #



          def branch(branch)
            ref("refs/remotes/origin/#{branch}") || ref("refs/heads/#{branch}")
          end

          def ref(ref)
            ref = connection.ref(ref)
            ref.target.oid if ref
          end

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
            release
          end

          def changes(old_sha, new_sha)
            find_commit old_sha
            find_commit new_sha
            DiffChanges.new `git --git-dir=#{git_dir} diff --name-status #{old_sha} #{new_sha}`
          end

          def git_path
            location
          end

          def to_s
            location
          end

          # !todo: Does this need to be a public method?
        protected
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

            # We have to call the GC.start (I think) to clean up
            # the objects hanging on to file descriptors.
            GC.start

            # We have to call connection.close to actually release
            # those file descriptors.
            connection.close
          end
          alias :release :close



        protected

          attr_reader :branch_location

          def connection
            @connection ||= connect!
          end

          def connect!
            Rugged::Repository.new(git_path)
          end

          def find_commit(sha)
            sha = sha.dup # in case sha is frozen; normalize_sha! will mutate it
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

          def name_of_branch(branch)
            branch.name
          end



        private

          def normalize_sha!(sha)
            return unless sha
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
              parent_sha: rugged_commit.parent_oids[0],
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

            # start by releasing any files we've got open
            release

            walker = Rugged::Walker.new(connection)
            push_shas.each { |sha| walker.push(sha) }
            hide_shas.each { |sha| walker.hide(sha) }

            results = []
            walker.each_with_index do |commit, i|
              release if i > 0 && i % 200 == 0
              results.push yield commit
              break if options[:limit] && (i + 1) >= options[:limit]
            end
            results

          ensure
            release
          end

        end
      end
    end
  end
end
