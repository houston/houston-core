class ConvertTicketsExtendedAttributesToProps < ActiveRecord::Migration[5.0]
  def up
    add_column :tickets, :props, :jsonb, default: {}
    add_column :tickets, :due_date, :date

    require "progressbar"
    tickets = Ticket.unscoped.all
    pbar = ProgressBar.new("tickets", tickets.count)
    tickets.find_each do |ticket|
      props = (ticket.read_attribute(:extended_attributes) || {}).each_with_object({}) do |(key, value), props|
        next if value.nil?
        case key
        when "clumsiness", "likelihood", "sequence", "seriousness"
          props["scheduler.#{key}"] = value.to_i
        when "postponed", "unable_to_set_estimated_effort", "unable_to_set_estimated_value", "unable_to_set_priority"
          props["scheduler.#{key.camelize(:lower)}"] = value == "true"
        when "estimated_value"
          props["scheduler.estimatedValue"] = value.to_f
        when "estimated_effort"
          props["scheduler.estimatedEffort"] = value.to_f
        when /^estimated_effort\[(\d+)\]$/
          props["scheduler.estimatedEffort.#{$1}"] = value.to_i.zero? ? value : value.to_i
        when /^estimated_value\[(\d+)\]$/
          props["scheduler.estimatedValue.#{$1}"] = value.to_i.zero? ? value : value.to_i

        when "milestoneSequence"
          props["roadmaps.milestoneSequence"] = value.to_i

        when "due_date"
          ticket.update_column :due_date, value
        end
      end

      ticket.update_column :props, props
      pbar.inc
    end
    pbar.finish
  end

  def down
    remove_column :tickets, :props
    remove_column :tickets, :due_date
  end
end
