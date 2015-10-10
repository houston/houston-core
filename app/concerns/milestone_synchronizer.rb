module MilestoneSynchronizer


  def fetch_all
    Houston.benchmark "GET All Milestones" do
      synchronize ticket_tracker.all_milestones
    end
  end

  def fetch_open
    Houston.benchmark "GET Open Milestones" do
      synchronize ticket_tracker.open_milestones
    end
  end


  def synchronize(unsynchronized_milestones)
    unsynchronized_milestones = unsynchronized_milestones.reject(&:nil?)
    return [] if unsynchronized_milestones.empty?

    Houston.benchmark("[milestones.synchronize] synchronizing with local milestones") do
      remote_ids = unsynchronized_milestones.map(&:remote_id)
      milestones = where(remote_id: remote_ids)

      unsynchronized_milestones.map do |unsynchronized_milestone|
        milestone = milestones.detect { |milestone| milestone.remote_id == unsynchronized_milestone.remote_id }
        attributes = unsynchronized_milestone.attributes
        if milestone

          # This is essentially a call to update_attributes,
          # but I broke it down so that we don't begin a
          # transaction if we don't have any changes to save.
          # This is pretty much just to reduce log verbosity.
          milestone.assign_attributes(attributes)
          milestone.save if milestone.changed?
        else
          milestone = create(attributes)
        end

        # There's no reason why this shouldn't be set,
        # but in order to reduce a bunch of useless hits
        # to the cache and a bunch of log output...
        milestone.project = project
        milestone
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
