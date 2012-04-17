class CreateTicketQueues < ActiveRecord::Migration
  def change
    create_table :ticket_queues do |t|
      t.integer :ticket_id
      t.string :queue
      t.timestamp :destroyed_at

      t.timestamps
    end
  end
end
