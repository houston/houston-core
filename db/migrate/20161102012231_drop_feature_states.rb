class DropFeatureStates < ActiveRecord::Migration[5.0]
  def up
    remove_column :projects, :feature_states
  end

  def down
    add_column :projects, :feature_states, :hstore
  end
end
