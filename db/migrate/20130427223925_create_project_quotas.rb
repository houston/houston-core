class CreateProjectQuotas < ActiveRecord::Migration
  def change
    create_table :project_quotas do |t|
      t.integer :project_id, null: false
      t.date :week, null: false
      t.integer :value, null: false

      t.timestamps
    end

    add_index :project_quotas, [:project_id, :week], unique: true
    add_index :project_quotas, :week
  end
end
