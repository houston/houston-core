module Houston
  module Adapters
    module VersionControl
      class GitAdapter
        class RemoteRepo < Repo
          
          
          def initialize(connection, location)
            super(connection)
            @location = location
          end
          
          
          
          # Public API for a VersionControl::Adapter Repo
          # ------------------------------------------------------------------------- #
          
          def ancestors_until(sha, *args)
            pull_and_retry(1) { super(sha, *args) }
          end
          
          attr_reader :location
          
          def native_commit(sha)
            pull_and_retry(1) { super(sha) }
          end
          
          def refresh!(async: false)
            GitAdapter.sync!(location, connection.path, async: async)
          end
          
          # ------------------------------------------------------------------------- #
          
          def to_s
            location.to_s
          end
          
          
          
        private
          
          def pull_and_retry(retries)
            begin
              yield
            rescue CommitNotFound
              if retries > 0
                retries -= 1
                refresh!
                retry
              else
                raise
              end
            end
          end
          
        end
      end
    end
  end
end
