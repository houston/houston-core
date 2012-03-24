class CreateProjects < ActiveRecord::Migration
  def change
    create_table :projects do |t|
      t.string :name
      t.string :slug
      t.integer :unfuddle_id
      t.string :git_url

      t.timestamps
    end
  end
end
