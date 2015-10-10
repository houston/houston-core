class CreateTicketPrerequisites < ActiveRecord::Migration
  def change
    create_table :ticket_prerequisites do |t|
      t.integer :ticket_id
      t.integer :project_id
      t.integer :prerequisite_ticket_number

      t.timestamps
    end

    add_index :ticket_prerequisites, :ticket_id
  end
end
