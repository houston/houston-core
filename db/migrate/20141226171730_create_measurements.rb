class CreateMeasurements < ActiveRecord::Migration
  def change
    create_table :measurements do |t|
      t.string :subject_type
      t.integer :subject_id
      t.string :name, null: false
      t.string :value, null: false
      t.timestamp :taken_at, null: false
      t.date :taken_on, null: false
      
      t.index [:subject_type, :subject_id]
      t.index :name
      t.index :taken_on
      t.index :taken_at
    end
  end
end
