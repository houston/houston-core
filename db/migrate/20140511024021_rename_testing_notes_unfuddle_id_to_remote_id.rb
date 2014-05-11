class RenameTestingNotesUnfuddleIdToRemoteId < ActiveRecord::Migration
  def change
    rename_column :testing_notes, :unfuddle_id, :remote_id
  end
end
