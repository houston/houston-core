class Team < ActiveRecord::Base
  include Houston::Props

  has_and_belongs_to_many :users, readonly: true
  has_many :projects
  has_many :roles, -> { joins(:user).merge(User.unretired) }, class_name: "TeamUser", dependent: :destroy, validate: false

  default_scope -> { order(name: :asc) }

  accepts_nested_attributes_for :roles, :allow_destroy => true, # <-- !todo: authorized access only
    reject_if: proc { |attrs| attrs[:user_id].blank? }



  Houston.config.roles.each do |role|
    collection_name = role.downcase.gsub(' ', '_').pluralize
    class_eval <<-RUBY
      has_many :#{collection_name}, -> { where(Role.arel_table[:name].eq("#{role}")) }, class_name: "User", through: :roles, source: :user
    RUBY
  end



  class << self
    def projects
      Project.where(team_id: all.select(:id))
    end

    def project_ids
      projects.ids
    end
  end



  def add_teammate(user_or_id, *desired_roles)
    teammate = roles.find_or_initialize_by((user_or_id.is_a?(User) ? :user : :user_id) => user_or_id)
    teammate.team = self
    teammate.roles = teammate.roles | desired_roles
    teammate.save!
  end

end
