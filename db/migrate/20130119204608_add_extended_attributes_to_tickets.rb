class AddExtendedAttributesToTickets < ActiveRecord::Migration
  def up
    add_column :tickets, :extended_attributes, :hstore

    Ticket.reset_column_information

    Ticket.nosync do
      Ticket.unscoped.find_each do |ticket|

        if ticket.project.nil?
          ticket.delete
          next
        end


        attrs = {}

        unless ticket.estimated_effort.blank? or ticket.estimated_effort.zero?
          attrs["estimated_effort"] = ticket.estimated_effort
        end

        unless ticket.estimated_value.blank? or ticket.estimated_value.zero?
          attrs["estimated_value"] = ticket.estimated_value
        end

        ticket.update_attribute(:extended_attributes, attrs) unless attrs.empty?

      end
    end
  end

  def down
    remove_column :tickets, :extended_attributes
  end
end
