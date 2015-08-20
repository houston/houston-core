class AddLabelsToPullRequests < ActiveRecord::Migration
  def change
    add_column :pull_requests, :labels, :text, null: false, default: ""
  end
end
