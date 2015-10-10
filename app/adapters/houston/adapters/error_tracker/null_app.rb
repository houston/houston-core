module Houston
  module Adapters
    module ErrorTracker
      class NullAppClass


        # Public API for a ErrorTracker app
        # ------------------------------------------------------------------------- #

        def project_url
        end

        def error_url(*args)
        end

        def problems_during(range)
          []
        end

        def open_problems(params={})
          []
        end

        def resolve!(problem_id, params={})
        end

        # ------------------------------------------------------------------------- #


        def nil?
          true
        end


      end

      NullApp = NullAppClass.new
    end
  end
end
