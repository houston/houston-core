module Houston
  module Adapters
    module VersionControl
      class NullCommit

        def sha
          Houston::NULL_GIT_COMMIT
        end

        def to_s
          sha[0...7]
        end

        def nil?
          true
        end

      end
    end
  end
end
