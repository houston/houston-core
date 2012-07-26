class AddMessageToRelease < ActiveRecord::Migration
  def change
    add_column :releases, :message, :text, :null => false, :default => ""
  end
end
