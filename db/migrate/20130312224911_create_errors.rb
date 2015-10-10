class CreateErrors < ActiveRecord::Migration
  def change
    create_table :errors do |t|
      t.integer :project_id
      t.string :category
      t.string :message
      t.text :backtrace

      t.timestamps
    end
  end
end
