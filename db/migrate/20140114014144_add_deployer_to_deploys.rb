class AddDeployerToDeploys < ActiveRecord::Migration
  def change
    add_column :deploys, :deployer, :string
  end
end
