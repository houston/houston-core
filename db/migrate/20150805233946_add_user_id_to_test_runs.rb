class AddUserIdToTestRuns < ActiveRecord::Migration
  def up
    add_column :test_runs, :user_id, :integer

    agent_emails = TestRun.reorder(nil).pluck("DISTINCT agent_email")
    user_id_by_agent_email = Hash[agent_emails.map { |agent_email|
      email = Mail::Address.new(agent_email)
      [agent_email, User.with_email_address(email.address).pluck(:id)[0]] }]

    puts "\e[94mAssociating users with test runs...\e[0m"
    pbar = ProgressBar.new("test runs", TestRun.count)
    TestRun.pluck(:agent_email, :id).each do |agent_email, id|
      user_id = user_id_by_agent_email[agent_email]
      TestRun.where(id: id).update_all(user_id: user_id) if user_id
      pbar.inc
    end
    pbar.finish
  end

  def down
    remove_column :test_runs, :user_id
  end
end
