class RenameProjectsColorToColorName < ActiveRecord::Migration[5.0]
  def change
    rename_column :projects, :color, :color_name
  end
end
