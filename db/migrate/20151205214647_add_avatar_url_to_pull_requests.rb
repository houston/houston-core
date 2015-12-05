class AddAvatarUrlToPullRequests < ActiveRecord::Migration
  def change
    add_column :pull_requests, :avatar_url, :string
  end
end
