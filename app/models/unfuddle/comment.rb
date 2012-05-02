class Unfuddle
  class Comment < Unfuddle::Base
    
    self.site = "https://#{Unfuddle.instance.subdomain}.unfuddle.com/api/v1" + "/projects/:project_id/tickets/:ticket_id"
    
    def project_id=(val)
      prefix_options[:project_id] = val
    end
    
    def ticket_id=(val)
      prefix_options[:ticket_id] = val
    end
    
    
  end
end
