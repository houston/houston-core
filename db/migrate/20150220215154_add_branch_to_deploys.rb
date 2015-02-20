class AddBranchToDeploys < ActiveRecord::Migration
  def change
    add_column :deploys, :branch, :string, :null => true
  end
end
