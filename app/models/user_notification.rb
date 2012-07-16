class UserNotification < ActiveRecord::Base
  
  belongs_to :user
  belongs_to :project
  
  validates_presence_of :user_id, :project_id, :environment
  
  def self.find_or_create(hash)
    find_or_create_by_user_id_and_project_id_and_environment(hash[:user_id], hash[:project_id], hash[:environment])
  end
  
end
