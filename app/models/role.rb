class Role < ActiveRecord::Base

  belongs_to :user
  belongs_to :project

  validates :user_id, presence: true
  validates :project, presence: true

  class << self
    def to_users
      User.where(id: all.select(:user_id))
    end

    def to_projects
      Project.where(id: all.select(:project_id))
    end

    def for_user(user_or_id)
      user_id = user_or_id.is_a?(User) ? user_or_id.id : user_or_id
      where user_id: user_id
    end

    def for_project(project_or_id)
      project_id = project_or_id.is_a?(Project) ? project_or_id.id : project_or_id
      where project_id: project_id
    end

    def any?
      count > 0
    end
  end

end
