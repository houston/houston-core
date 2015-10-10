class RequireSprintsToBeUnique < ActiveRecord::Migration
  def up
    add_index :sprints, :end_date, unique: true
  end

  def down
    remove_index :sprints, :end_date
  end
end
