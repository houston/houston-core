class AddDeployIdToReleases < ActiveRecord::Migration
  def change
    add_column :releases, :deploy_id , :integer
    add_index :releases, :deploy_id
  end
end
