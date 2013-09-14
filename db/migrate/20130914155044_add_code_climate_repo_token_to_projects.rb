class AddCodeClimateRepoTokenToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :code_climate_repo_token, :string, :null => false, :default => ""
  end
end
