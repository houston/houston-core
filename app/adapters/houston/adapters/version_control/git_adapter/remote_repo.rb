module Houston
  module Adapters
    module VersionControl
      class GitAdapter
        class RemoteRepo < Repo
          RETRY_COOLDOWN = 4 # seconds



          def initialize(git_path, location)
            super location
            @git_path = git_path.to_s
            @branch_location = :remote
          end



          # Public API for a VersionControl::Adapter Repo
          # ------------------------------------------------------------------------- #

          def refresh!(async: false)
            return clone!(async: async) unless exists?
            pull!(async: async)
          end

          # ------------------------------------------------------------------------- #



          def before_update(project)
            return true unless project.slug_changed?
            rename *project.changes[:slug]
          end

          def git_path
            @git_path
          end

          def clone!(async: false)
            async ? Houston.async { _clone!(true) } : _clone!(false)
          end

          def pull!(async: false)
            async ? Houston.async { _pull!(true) } : _pull!(false)
          end

          def origin
            @origin ||= connection.remotes["origin"]
          end



        protected

          def connect!
            clone! unless exists?
            super
          end

          def find_commit(sha)
            pull_and_retry { super(sha) }
          end

          def name_of_branch(branch)
            super.gsub /^origin\//, ""
          end



        private

          def pull_and_retry
            begin
              yield
            rescue CommitNotFound
              raise if @last_retry && Time.now - @last_retry < RETRY_COOLDOWN
              refresh!
              @last_retry = Time.now
              retry
            end
          end

          def _clone!(async)
            Houston.benchmark("[git:clone#{":async" if async}] #{location} => #{git_path}") do
              Rugged::Repository.clone_at location, git_path,
                credentials: GitAdapter.credentials,
                bare: true
            end
          end

          def _pull!(async)
            Houston.benchmark("[git:pull#{":async" if async}] #{location} => #{git_path}") do
              options = {credentials: GitAdapter.credentials}

              # Fetch
              Houston.try({max_tries: 3, base: 0}, Rugged::OSError, Rugged::SshError) do
                connection.remotes["origin"].fetch(nil, options.merge({
                  update_tips: Proc.new do |refname, _, new_oid|
                    if new_oid.nil?
                      Rails.logger.debug "[git:pull] Deleting #{refname}"
                      connection.references.delete(refname)
                    else
                      Rails.logger.debug "[git:pull] Setting #{refname} to #{new_oid[0...7]}"
                      connection.references.create(refname, new_oid, force: true)
                    end
                  end
                }))
                release
              end

              # Don't prune local branches, just local references to remote branches
              local_refs = connection.refs.map(&:name)
                .grep(/^refs\/remotes\//)

              # These are represented as branches (refs/heads/) remotely, but
              # as remote tips (refs/remotes/origin/) locally.
              remote_refs = connection.remotes["origin"].ls(options)
                .map { |attrs| attrs[:name] }
                .grep(/^refs\//)
                .map { |name| name.gsub("refs/heads/", "refs/remotes/origin/") }

              # Prune references to branches that were deleted from origin
              prune_refs = local_refs - remote_refs
              prune_refs.each do |ref|
                begin
                  connection.references.delete(ref)
                rescue Rugged::ReferenceError
                  # Ignore
                end
              end
            end
          rescue
            $!.additional_information[:repo] = to_s
            $!.additional_information[:path] = git_dir
            raise
          ensure
            close
          end

          def rename(from, to)
            old_git_path = Houston.root.join("tmp", "#{from}.git").to_s
            new_git_path = Houston.root.join("tmp", "#{to}.git").to_s

            unless File.exists?(old_git_path)
              Rails.logger.info "\e[34m[remote_repo.rename] #{old_git_path} does not exist\e[0m"
              @git_path = new_git_path
              remove_instance_variable :@connection if defined?(@connection)
              return true
            end

            if system "mv #{old_git_path} #{new_git_path}"
              Rails.logger.info "\e[32m[remote_repo.rename] Renamed #{old_git_path} to #{File.basename(new_git_path)}\e[0m"
              @git_path = new_git_path
              remove_instance_variable :@connection if defined?(@connection)
              return true
            end

            Rails.logger.warn "\e[31m[remote_repo.rename] Failed to rename #{old_git_path} to #{File.basename(new_git_path)}\e[0m"
            false
          end

        end
      end
    end
  end
end
