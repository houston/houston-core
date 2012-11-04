class CreateChangeTags < ActiveRecord::Migration
  def change
    create_table :change_tags do |t|
      t.string :name
      t.string :color, :limit => 6
      
      t.timestamps
    end
    
    add_index :change_tags, [:name]
  end
end
