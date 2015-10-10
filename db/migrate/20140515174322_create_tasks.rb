class CreateTasks < ActiveRecord::Migration
  def change
    create_table :tasks do |t|
      t.integer :ticket_id, null: false
      t.integer :number, null: false
      t.string :description, null: false, length: 80
      t.decimal :effort, :precision => 6, :scale => 2 # 1234.56

      t.timestamp :first_release_at
      t.timestamp :first_commit_at
      t.integer :sprint_id
      t.timestamp :checked_out_at
      t.integer :checked_out_by_id

      t.timestamps

      t.index [:ticket_id, :number], unique: true
    end
  end
end
