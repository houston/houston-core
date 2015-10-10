class CreateSprints < ActiveRecord::Migration
  def change
    create_table :sprints do |t|
      t.integer :project_id, null: false
      t.date :end_date

      t.timestamps
    end

    add_index :sprints, [:project_id, :end_date]

    add_column :tickets, :sprint_id, :integer
    add_index :tickets, :sprint_id
  end
end
