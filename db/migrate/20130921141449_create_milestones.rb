class CreateMilestones < ActiveRecord::Migration
  def change
    create_table :milestones do |t|
      t.integer :project_id, null: false
      t.integer :remote_id
      t.string :name, null: false
      t.integer :tickets_count, default: 0
      t.timestamp :completed_at
      t.hstore :extended_attributes

      t.timestamps
    end

    add_index :milestones, :project_id

    add_column :tickets, :milestone_id, :integer
    add_index :tickets, :milestone_id
  end
end
