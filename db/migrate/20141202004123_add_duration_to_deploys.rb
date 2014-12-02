class AddDurationToDeploys < ActiveRecord::Migration
  def change
    add_column :deploys, :duration, :integer
  end
end
