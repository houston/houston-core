class AddUnfuddleIdToTickets < ActiveRecord::Migration
  def up
    add_column :tickets, :unfuddle_id, :integer
    
    Project.where("unfuddle_id>0").each do |project|
      ticket_numbers = project.tickets.pluck(:number)
      puts "#{project.slug}: #{ticket_numbers.join(", ")}"
      ticket_numbers.in_groups_of(10).each do |numbers|
        project.find_tickets(:number => numbers)
      end
    end
  end
  
  def down
    remove_column :tickets, :unfuddle_id
  end
end
