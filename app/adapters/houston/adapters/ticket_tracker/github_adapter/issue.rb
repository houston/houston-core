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
            @resolution       = ""
            @milestone_id     = nil
            @type             = get_type
            @created_at       = Time.parse(attributes["created_at"]) if attributes["created_at"]
            @closed_at        = Time.parse(attributes["closed_at"]) if attributes["closed_at"]
            
            # optional
            @tags             = attributes.fetch("labels", []).map(&method(:tag_from_label))
          end
          
          attr_reader :raw_attributes,
                      
                      :remote_id,
                      :number,
                      :summary,
                      :description,
                      :resolution,
                      :milestone_id,
                      :type,
                      :tags,
                      :created_at,
                      :closed_at
          
          def attributes
            { remote_id:      remote_id,
              number:         number,
              summary:        summary,
              description:    description,
              resolution:     resolution,
              milestone_id:   milestone_id,
              type:           type,
              created_at:     created_at,
              closed_at:      closed_at,
              
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
          
          
          
          def close!
            connection.close_issue(connection.repo_path, number)
          end
          
          
          
          # !todo: refactor this method to be more generic and abstract
          def update_attribute(attribute, value)
            case attribute
            when :deployment
              # do nothing
            else
              raise NotImplementedError
            end
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
