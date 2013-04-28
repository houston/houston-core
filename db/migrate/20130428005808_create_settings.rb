class CreateSettings < ActiveRecord::Migration
  def change
    create_table :settings do |t|
      t.string :name, null: false
      t.string :value, null: false
    end
  end
end
