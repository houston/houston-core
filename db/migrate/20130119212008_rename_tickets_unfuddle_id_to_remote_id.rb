class RenameTicketsUnfuddleIdToRemoteId < ActiveRecord::Migration
  def change
    rename_column :tickets, :unfuddle_id, :remote_id
  end
end
