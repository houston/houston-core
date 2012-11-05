class AddTagSlugToChanges < ActiveRecord::Migration
  def change
    add_column :changes, :tag_slug, :string
  end
end
