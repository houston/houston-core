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
            
            # optional
            @tags             = attributes.fetch("labels", []).map(&method(:tag_from_label))
          end
          
          attr_reader :remote_id,
                      :number,
                      :summary,
                      :description,
                      :tags
          
          def attributes
            { remote_id:      remote_id,
              number:         number,
              summary:        summary,
              description:    description,
              
              tags:           tags,
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
          
          
          
        private
          
          def tag_from_label(label)
            TicketTag.new(label["name"], label["color"])
          end
          
        end
      end
    end
  end
end
