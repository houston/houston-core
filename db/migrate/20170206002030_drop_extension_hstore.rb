class DropExtensionHstore < ActiveRecord::Migration[5.0]
  def up
    disable_extension "hstore"
  end

  def down
    enable_extension "hstore"
  end
end
