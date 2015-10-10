class AddProjectIdToCommits < ActiveRecord::Migration
  def up
    add_column :commits, :project_id, :integer

    Commit.reset_column_information
    Commit.find_each do |commit|
      release = commit.release

      if release.nil?
        commit.delete
        Rails.logger.warn "Deleting commit ##{commit.id} (#{commit.attributes.inspect})"
        next
      end

      commit.update_column(:project_id, release.project_id)
    end

    change_column_null :commits, :project_id, false

    add_index :commits, [:project_id]
  end

  def down
    remove_column :commits, :project_id
  end
end
