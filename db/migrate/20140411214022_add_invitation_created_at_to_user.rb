class AddInvitationCreatedAtToUser < ActiveRecord::Migration
  def change
    add_column :users, :invitation_created_at, :datetime
  end
end
