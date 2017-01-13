class AddPropsToPullRequests < ActiveRecord::Migration
  def change
    add_column :pull_requests, :props, :jsonb, default: {}
  end
end
