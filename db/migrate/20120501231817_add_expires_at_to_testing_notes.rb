class AddExpiresAtToTestingNotes < ActiveRecord::Migration
  def change
    add_column :testing_notes, :expires_at, :timestamp
  end
end
