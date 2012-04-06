class AddInitialCommitToEnvironments < ActiveRecord::Migration
  def change
    add_column :environments, :initial_commit, :string
  end
end
