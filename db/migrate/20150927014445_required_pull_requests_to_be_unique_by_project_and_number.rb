class RequiredPullRequestsToBeUniqueByProjectAndNumber < ActiveRecord::Migration
  def up
    while (ids = select_values("select max(id) from pull_requests group by project_id, number having count(id) > 1")).any?
      Github::PullRequest.where(id: ids).delete_all
    end

    add_index :pull_requests, [:project_id, :number], unique: true
  end

  def down
    remove_index :pull_requests, [:project_id, :number]
  end
end
