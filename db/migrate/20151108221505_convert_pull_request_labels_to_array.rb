class ConvertPullRequestLabelsToArray < ActiveRecord::Migration
  def up
    rename_column :pull_requests, :labels, :old_labels
    add_column :pull_requests, :labels, :text, array: true, default: []

    Github::PullRequest.reset_column_information
    Github::PullRequest.pluck(:id, :old_labels).each do |id, old_labels|
      Github::PullRequest.where(id: id).update_all(labels: old_labels.split(/\n/))
    end
  end

  def down
    raise IrreversibleMigration unless Github::PullRequest.column_names.member? "old_labels"

    Github::PullRequest.pluck(:id, :labels).each do |id, labels|
      Github::PullRequest.where(id: id).update_all(old_labels: Array(labels).uniq.join("\n"))
    end

    remove_column :pull_requests, :labels
    rename_column :pull_requests, :old_labels, :labels
  end
end
