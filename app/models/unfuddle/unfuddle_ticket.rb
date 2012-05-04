class Unfuddle
  class UnfuddleTicket
    
    
    
    def initialize(project, ticket_id)
      @project = project
      @ticket_id = ticket_id
    end
    
    attr_reader :project, :ticket_id
    
    delegate :unfuddle, :project_id, :to => :project 
    
    
    
    def update_attribute(attribute, value)
      path = "/projects/#{project_id}/tickets/#{ticket_id}.xml"
      xml = "<ticket><#{attribute}>#{value}</#{attribute}></ticket>"
      unfuddle.put(path, xml)
    end
    
    
    
  end
end
