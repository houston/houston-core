module TicketSynchronizer
  
  
  def fetch_all
    synchronize ticket_tracker.all_tickets
  end
  
  def fetch_open
    synchronize ticket_tracker.open_tickets
  end
  
  def fetch_numbered(numbers)
    synchronize ticket_tracker.find_tickets_numbered(numbers)
  end
  
  def fetch_with_query(*query)
    return [] unless ticket_tracker.respond_to?(:find_tickets!) # <-- an optional API
    
    Rails.logger.info "[tickets.fetch_with_query] query: #{query.inspect}"
    
    synchronize ticket_tracker.find_tickets!(*query)
  end
  
  
  def synchronize(unsynchronized_tickets)
    unsynchronized_tickets = unsynchronized_tickets.reject(&:nil?)
    return [] if unsynchronized_tickets.empty?
    
    map_milestone_id = project.milestones.remote_id_map
    
    Project.benchmark("\e[33m[tickets.synchronize] synchronizing with local tickets\e[0m") do
      numbers = unsynchronized_tickets.map(&:number)
      tickets = includes(:ticket_prerequisites).where(number: numbers)
      
      unsynchronized_tickets.map do |unsynchronized_ticket|
        ticket = tickets.detect { |ticket| ticket.number == unsynchronized_ticket.number }
        attributes = unsynchronized_ticket.attributes
        
        # Convert remote milestone IDs to local milestone IDs
        attributes[:milestone_id] = map_milestone_id[attributes[:milestone_id]]
        
        if ticket
          
          # This is essentially a call to update_attributes,
          # but I broke it down so that we don't begin a
          # transaction if we don't have any changes to save.
          # This is pretty much just to reduce log verbosity.
          ticket.assign_attributes(attributes)
          
          # hstore always thinks it has changed
          has_legitimate_changes = ticket.changed?
          if has_legitimate_changes && ticket.changed == %w{extended_attributes}
            before, after = ticket.changes["extended_attributes"]
            has_legitimate_changes = false if before == after
          end
          Ticket.nosync { ticket.save } if has_legitimate_changes
        else
          ticket = Ticket.nosync { create(attributes) }
        end
        
        # There's no reason why this shouldn't be set,
        # but in order to reduce a bunch of useless hits
        # to the cache and a bunch of log output...
        ticket.project = project
        ticket
      end
    end
  end
  
  
private
  
  def ticket_tracker
    project.ticket_tracker
  end
  
  def project
    proxy_association.owner
  end
  
end
