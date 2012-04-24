class CreateTestingNotes < ActiveRecord::Migration
  def change
    create_table :testing_notes do |t|
      t.belongs_to :user
      t.belongs_to :ticket
      t.string :verdict, :null => false
      t.string :comment, :null => false, :default => ""

      t.timestamps
    end
    add_index :testing_notes, :user_id
    add_index :testing_notes, :ticket_id
  end
end
