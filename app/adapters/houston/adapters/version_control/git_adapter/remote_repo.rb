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
          
          def commits_between(sha1, sha2)
            pull_and_retry(1) { super(sha1, sha2) }
          end
          
          attr_reader :location
          
          def native_commit(sha)
            pull_and_retry(1) { super(sha) }
          end
          
          def refresh!
            pull!
          end
          
          # ------------------------------------------------------------------------- #
          
          
          
        private
          
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
          
        end
      end
    end
  end
end
