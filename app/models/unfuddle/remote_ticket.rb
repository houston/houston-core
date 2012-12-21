class Unfuddle
  class RemoteTicket < ActiveResource::Base
    
    self.format               = :json
    self.include_root_in_json = true
    self.user                 = Unfuddle.instance.username
    self.password             = Unfuddle.instance.password
    self.element_name         = "ticket"
    # self.site                 = "https://#{Unfuddle.instance.subdomain}.unfuddle.com/api/v1"
    self.site                 = "https://#{Unfuddle.instance.subdomain}.unfuddle.com/api/v1" + "/projects/:project_id"
    
    
    def hours_estimate_current=(value)
      super value.to_f
    end
    
    def hours_estimate_initial=(value)
      super value.to_f
    end
    
    
    def to_json(options={})
      options.reverse_merge!(
        :root => self.class.element_name,
        :only => ::Ticket.remote_attribute_names)
      super
    end
    
    
    def project_id=(val)
      prefix_options[:project_id] = val
    end
    
  end
end
