class CreateValueStatements < ActiveRecord::Migration
  def change
    create_table :value_statements do |t|
      t.integer :project_id, null: false
      t.float :weight, null: false
      t.string :text, null: false
    end
  end
end
