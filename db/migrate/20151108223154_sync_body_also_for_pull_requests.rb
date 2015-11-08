class SyncBodyAlsoForPullRequests < ActiveRecord::Migration
  def change
    add_column :pull_requests, :body, :text
  end
end
