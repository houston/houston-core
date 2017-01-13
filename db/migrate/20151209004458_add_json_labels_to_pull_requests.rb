class AddJsonLabelsToPullRequests < ActiveRecord::Migration
  def change
    add_column :pull_requests, :json_labels, :jsonb, default: []
  end
end
