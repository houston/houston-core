class AddUnfuddleIdToTestingNotes < ActiveRecord::Migration
  def change
    add_column :testing_notes, :unfuddle_id, :integer
  end
end
