class ConvertUserViewOptionsToProps < ActiveRecord::Migration
  def up
    add_column :users, :props, :jsonb, default: {}

    require "progressbar"
    users = User.all
    pbar = ProgressBar.new("users", users.count)
    users.find_each do |user|
      props = user.read_attribute(:view_options) || {}
      props["github.username"] = props.delete("github_username") if props.key?("github_username")
      props["slack.username"] = props.delete("slack_username") if props.key?("slack_username")
      user.update_column :props, props
      pbar.inc
    end
    pbar.finish
  end

  def down
    remove_column :users, :props
  end
end
