class AddOutputToDeploy < ActiveRecord::Migration
  def change
    add_column :deploys, :output, :text
  end
end
