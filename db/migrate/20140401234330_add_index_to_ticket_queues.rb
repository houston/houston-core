class AddIndexToTicketQueues < ActiveRecord::Migration
  def change
    add_index :ticket_queues, :ticket_id
    add_index :ticket_queues, :queue
  end
end
