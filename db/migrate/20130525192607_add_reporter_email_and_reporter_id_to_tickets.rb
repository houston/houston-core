class AddReporterEmailAndReporterIdToTickets < ActiveRecord::Migration
  def change
    add_column :tickets, :reporter_email, :string
    add_column :tickets, :reporter_id, :integer
  end
end
