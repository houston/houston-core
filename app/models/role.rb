class Role < ActiveRecord::Base
  
  belongs_to :user
  belongs_to :project
  
  validates :user_id, presence: true
  validates :project, presence: true
  validates :name, presence: true, inclusion: {in: Houston.config.project_roles, message: "\"%{value}\" is unknown. It must be #{Houston.config.project_roles.to_sentence(last_word_connector: ", or ")}"}
  
  
  Houston.config.project_roles.each do |role|
    method_name = role.downcase.gsub(' ', '_')
    class_eval <<-RUBY
    def #{method_name}?
      name == "#{role}"
    end
    
    def self.#{method_name.pluralize}
      where(name: "#{role}")
    end
    RUBY
  end
  
  
  class << self
    
    def participants
      where arel_table[:name].not_eq("Follower")
    end
    
    def to_users
      User.where(id: scoped.select(:user_id))
    end
    
    def to_projects
      Project.where(id: scoped.select(:project_id))
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
      scoped.count > 0
    end
    
  end
  
end
