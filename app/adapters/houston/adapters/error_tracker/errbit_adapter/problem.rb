module Houston
  module Adapters
    module ErrorTracker
      class ErrbitAdapter
        class Problem
          
          def initialize(attributes={})
            @attributes = attributes
          end
          
          attr_reader :attributes
          attr_accessor :err_ids
          attr_accessor :ticket
          
          def first_notice_at
            attributes[:first_notice_at]
          end
          
          def first_notice_commit
            attributes[:first_notice_commit]
          end
          
          def first_notice_environment
            attributes[:first_notice_environment]
          end
          
          def last_notice_at
            attributes[:last_notice_at]
          end
          
          def last_notice_commit
            attributes[:last_notice_commit]
          end
          
          def last_notice_environment
            attributes[:last_notice_environment]
          end
          
          def notices_count
            attributes[:notices_count]
          end
          
          
          def resolved_at
            attributes[:resolved_at]
          end
          
          def resolved?
            attributes[:resolved]
          end
          
          
          def app_id
            attributes[:app_id]
          end
          
          def message
            attributes[:message]
          end
          
          def where
            attributes[:where]
          end
          
          def environment
            attributes[:environment]
          end
          
          def url
            attributes[:url]
          end
          
        end
      end
    end
  end
end
