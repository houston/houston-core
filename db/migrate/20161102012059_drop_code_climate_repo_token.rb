class DropCodeClimateRepoToken < ActiveRecord::Migration[5.0]
  def up
    remove_column :projects, :code_climate_repo_token
  end

  def down
    add_column :projects, :code_climate_repo_token, :string, null: false, default: ""
  end
end
