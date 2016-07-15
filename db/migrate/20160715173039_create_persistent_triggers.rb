class CreatePersistentTriggers < ActiveRecord::Migration
  def change
    create_table :persistent_triggers do |t|
      t.string :type, null: false
      t.text :value, null: false
      t.text :params, null: false, default: "{}"
      t.string :action, null: false
    end
  end
end
