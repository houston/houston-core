class CreateEnvironments < ActiveRecord::Migration
  def change
    create_table :environments do |t|
      t.string :slug
      t.string :name
      t.integer :project_id

      t.timestamps
    end
  end
end
