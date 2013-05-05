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
            @type             = get_type
            
            # optional
            @tags             = attributes.fetch("labels", []).map(&method(:tag_from_label))
          end
          
          attr_reader :raw_attributes,
                      
                      :remote_id,
                      :number,
                      :summary,
                      :description,
                      :type,
                      :tags
          
          def attributes
            { remote_id:      remote_id,
              number:         number,
              summary:        summary,
              description:    description,
              type:           type,
              
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
          
          attr_reader :connection
          alias :github :connection
          
          def get_type
            identify_type_proc = github.config[:identify_type]
            identify_type_proc.call(self) if identify_type_proc
          end
          
          def tag_from_label(label)
            TicketTag.new(label["name"], label["color"])
          end
          
        end
      end
    end
  end
end
