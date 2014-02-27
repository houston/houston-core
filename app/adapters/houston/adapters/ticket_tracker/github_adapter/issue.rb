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
            @reporter_email   = attributes["user"]["email"]
            @resolution       = ""
            @milestone_id     = nil
            @type             = get_type
            @created_at       = attributes["created_at"] if attributes["created_at"]
            @closed_at        = attributes["closed_at"] if attributes["closed_at"]
            
            # optional
            @tags             = get_tags
          end
          
          attr_reader :raw_attributes,
                      
                      :remote_id,
                      :number,
                      :summary,
                      :description,
                      :reporter_email,
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
              reporter_email: reporter_email,
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
            connection.close_issue(number)
          end
          
          def resolve!
            close!
          end
          
          def reopen!
            connection.reopen_issue(number)
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
          
          def get_tags
            identify_tags_proc = github.config[:identify_tags]
            return Array(attributes["labels"]).map(&method(:tag_from_label)) unless identify_tags_proc
            identify_tags_proc.call(self)
          end
          
          def tag_from_label(label)
            TicketTag.new(label["name"], label["color"])
          end
          
        end
      end
    end
  end
end
