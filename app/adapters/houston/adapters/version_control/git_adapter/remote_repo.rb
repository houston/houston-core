module Houston
  module Adapters
    module VersionControl
      class GitAdapter
        class RemoteRepo < Repo
          RETRY_COOLDOWN = 4 # seconds
          
          
          def initialize(connection, location)
            super(connection)
            @location = location
          end
          
          
          
          # Public API for a VersionControl::Adapter Repo
          # ------------------------------------------------------------------------- #
          
          attr_reader :location
          
          def refresh!(async: false)
            return clone!(async: async) unless exists?
            pull!(async: async)
          end
          
          # ------------------------------------------------------------------------- #
          
          def to_s
            location.to_s
          end
          
          
          
          def clone!(async: false)
            GitAdapter.clone!(location, connection.path, async: false)
          end
          
          def pull!(async: false)
            async ? Houston.async { _pull!(true) } : _pull!(false)
          end
          
          
          
        protected
          
          def find_commit(sha)
            pull_and_retry { super(sha) }
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
          
          def _pull!(async)
            Houston.benchmark("[git:pull#{":async" if async}] #{connection.path}") do
              options = {credentials: GitAdapter.credentials}
              
              # Fetch
              Houston.try({max_tries: 3, base: 0}, Rugged::OSError) do
                connection.remotes["origin"].fetch(nil, options)
                release
              end
              
              # Prune
              local_refs = connection.refs.map(&:name).grep(/^refs\//)
              remote_refs = connection.remotes["origin"].ls(options)
                .map { |attrs| attrs[:name] }.grep(/^refs\//)
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
            $!.additional_information[:path] = connection.path
            raise
          ensure
            close
          end
          
        end
      end
    end
  end
end
