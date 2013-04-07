class CreateRoles < ActiveRecord::Migration
  def change
    create_table :roles do |t|
      t.references :user
      t.references :project
      t.string :name, null: false
      
      t.timestamps
    end
    
    add_index :roles, [:user_id, :project_id]
    add_index :roles, [:user_id, :project_id, :name]
  end
end
