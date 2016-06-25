class MoveUsersUnfuddleIdToProps < ActiveRecord::Migration
  def up
    require "progressbar"
    users = User.all
    pbar = ProgressBar.new("users", users.count)
    users.find_each do |user|
      if unfuddle_id = user.read_attribute(:unfuddle_id)
        user.update_prop! "unfuddle.id", unfuddle_id
      end
      pbar.inc
    end
    pbar.finish
  end
end
