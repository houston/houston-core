module Houston
  module Adapters
    module VersionControl
      class Commit
        
        def initialize(attributes={})
          @sha = attributes[:sha]
          @message = attributes[:message]
          @date = attributes[:date]
          @author_name = attributes[:author_name]
          @author_email = attributes[:author_email]
        end
        
        attr_reader :sha, :message, :date, :author_name, :author_email
        
      end
    end
  end
end
