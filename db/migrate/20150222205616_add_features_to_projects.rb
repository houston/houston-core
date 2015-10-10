class AddFeaturesToProjects < ActiveRecord::Migration
  def up
    add_column :projects, :selected_features, :text, array: true

    Project.reset_column_information
    Project.update_all(selected_features: Houston.config.project_features)
  end

  def down
    remove_column :projects, :selected_features
  end
end
