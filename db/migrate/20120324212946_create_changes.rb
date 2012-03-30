class CreateChanges < ActiveRecord::Migration
  def change
    create_table :changes do |t|
      t.integer :release_id
      t.string :description
      t.integer :ticket_number

      t.timestamps
    end
  end
end
