class CreatePullRequests < ActiveRecord::Migration
  def change
    create_table :pull_requests do |t|
      t.references :project, null: false
      t.references :user

      t.string :title, null: false
      t.integer :number, null: false
      t.string :repo, null: false
      t.string :username, null: false
      t.string :url, null: false
      t.string :base_ref, null: false
      t.string :base_sha, null: false
      t.string :head_ref, null: false
      t.string :head_sha, null: false

      t.index :project_id
    end

    create_table :commits_pull_requests, id: false do |t|
      t.references :commit, :pull_request
      t.index [:commit_id, :pull_request_id], unique: true
    end
  end
end
