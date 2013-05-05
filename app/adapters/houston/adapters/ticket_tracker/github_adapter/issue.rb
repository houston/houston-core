module Houston
  module Adapters
    module TicketTracker
      class GithubAdapter
        class Issue
          
          
          
          def initialize(connection, attributes)
            @connection       = connection
            @raw_attributes   = attributes
            
            # required
            @remote_id        = attributes["id"]
            @number           = attributes["number"]
            @summary          = attributes["title"]
            @description      = attributes["body"]
          end
          
          attr_reader :remote_id,
                      :number,
                      :summary,
                      :description
          
          def attributes
            { remote_id:      remote_id,
              number:         number,
              summary:        summary,
              description:    description,
              
              antecedents:    antecedents,
              deployment:     deployment,
              prerequisites:  [] }
          end
          
          def antecedents
            []
          end
          
          def deployment
            nil
          end
          
          
          
          def update_attribute(*args)
            raise NotImplementedError, "Haven't implemted Github::Issue#update_attribute (#{args.inspect})"
          end
          
        end
      end
    end
  end
end
