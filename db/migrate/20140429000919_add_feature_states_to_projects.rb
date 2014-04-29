class AddFeatureStatesToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :feature_states, :hstore
  end
end
