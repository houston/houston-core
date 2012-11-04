class AddTagIdToChanges < ActiveRecord::Migration
  def change
    add_column :changes, :tag_id, :integer
  end
end
