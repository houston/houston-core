class CreateProjects < ActiveRecord::Migration
  def change
    create_table :projects do |t|
      t.string :title
      t.string :slug
      t.integer :unfuddle_id

      t.timestamps
    end
  end
end
