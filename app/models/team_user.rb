class TeamUser < ActiveRecord::Base

  belongs_to :user
  belongs_to :team
  has_many :projects, through: :team

  validates :user_id, presence: true
  validates :team, presence: true
  validate :roles_should_all_be_defined_by_config



  Houston.config.roles.each do |role|
    method_name = role.downcase.gsub(' ', '_')
    class_eval <<-RUBY
    def #{method_name}?
      name == "#{role}"
    end

    def self.#{method_name.pluralize}
      with_role("#{role}")
    end
    RUBY
  end



  class << self
    def to_users
      User.where(id: all.select(:user_id))
    end

    def to_projects
      Project.where(team_id: all.select(:team_id))
    end

    def with_role(role)
      where ["? = ANY(roles)", role]
    end

    def for_user(user_or_id)
      user_id = user_or_id.is_a?(User) ? user_or_id.id : user_or_id
      where user_id: user_id
    end

    def any?
      count > 0
    end
  end



  def roles
    super || []
  end



private

  def roles_should_all_be_defined_by_config
    roles.each do |role|
      next if Houston.config.roles.member?(role)
      errors.add :roles, "includes #{role.inspect} which is not a defined role (#{Houston.config.roles.join(", ")})"
    end
  end

end
