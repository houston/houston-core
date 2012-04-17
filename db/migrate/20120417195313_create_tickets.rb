class CreateTickets < ActiveRecord::Migration
  def change
    create_table :tickets do |t|
      t.integer :project_id
      t.integer :number
      t.string :summary
      t.text :description

      t.timestamps
    end
  end
end
