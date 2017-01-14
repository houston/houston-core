module TicketSynchronizer


  def fetch_all
    return all if !ticket_tracker.supports?(:syncing_tickets)

    Houston.benchmark "GET All Tickets" do
      synchronize ticket_tracker.all_tickets
    end
  end

  def fetch_open
    return open if !ticket_tracker.supports?(:syncing_tickets)

    Houston.benchmark "GET Open Tickets" do
      synchronize ticket_tracker.open_tickets
    end
  end

  def find_by_number!(number)
    numbered(number, sync: true).first || (raise ActiveRecord::RecordNotFound)
  end

  def numbered(*numbers, sync: false)
    numbers = numbers.flatten.map(&:to_i).uniq
    return none if numbers.empty?

    results = super(*numbers).to_a
    return results unless sync && ticket_tracker.supports?(:syncing_tickets)

    results.concat fetch_numbered(numbers - results.map(&:number))
  end

  def fetch_numbered(numbers)
    return [] if numbers.empty?
    return numbered(numbers) if !ticket_tracker.supports?(:syncing_tickets)

    Houston.benchmark "GET Numbered Tickets" do
      synchronize ticket_tracker.find_tickets_numbered(numbers)
    end
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

    Houston.benchmark("[tickets.synchronize] synchronizing #{unsynchronized_tickets.length} tickets") do
      numbers = unsynchronized_tickets.map(&:number)
      tickets = Ticket.unscoped { where(number: numbers) }

      unsynchronized_tickets.map do |unsynchronized_ticket|
        ticket = tickets.detect { |ticket| ticket.number == unsynchronized_ticket.number }
        attributes = unsynchronized_ticket.attributes.merge(destroyed_at: nil)

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
          if has_legitimate_changes && ticket.changed == %w{props}
            before, after = ticket.changes["props"]
            has_legitimate_changes = false if before == after
          end
          if has_legitimate_changes
            ticket.updated_by = project.ticket_tracker_name
            Ticket.nosync do
              unless ticket.save
                Rails.logger.warn "\e[31mFailed to update ticket \e[1m#{project.slug}##{ticket.number}\e[0;31m: #{ticket.errors.full_messages.to_sentence}\e[0m"
              end
            end
          end
        else
          ticket = Ticket.nosync { create(attributes) }
          unless ticket.persisted?
            Rails.logger.warn "\e[31mFailed to create ticket \e[1m#{project.slug}##{ticket.number}\e[0;31m: #{ticket.errors.full_messages.to_sentence}\e[0m"
          end
        end

        # There's no reason why this shouldn't be set,
        # but in order to reduce a bunch of useless hits
        # to the cache and a bunch of log output...
        ticket.project = project
        ticket
      end
    end
  end


  def create_from_remote(remote_ticket)
    attributes = remote_ticket.attributes
    if project.ticket_tracker.features.include?(:syncing_milestones)
      attributes[:milestone_id] = project.milestones.id_for_remote_id(attributes[:milestone_id])
    end
    create(attributes)
  end


private

  def ticket_tracker
    project.ticket_tracker
  end

  def project
    proxy_association.owner
  end

end
