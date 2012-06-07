class Unfuddle
  class Comment < ActiveResource::Base
    
    self.format               = :json
    self.include_root_in_json = true
    self.user                 = Unfuddle.instance.username
    self.password             = Unfuddle.instance.password
    # self.site                 = "https://#{Unfuddle.instance.subdomain}.unfuddle.com/api/v1"
    self.site                 = "https://#{Unfuddle.instance.subdomain}.unfuddle.com/api/v1" + "/projects/:project_id/tickets/:ticket_id"
    
    def project_id=(val)
      prefix_options[:project_id] = val
    end
    
    def ticket_id=(val)
      prefix_options[:ticket_id] = val
    end
    
  end
end
