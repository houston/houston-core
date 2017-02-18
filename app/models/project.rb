class Project < ActiveRecord::Base
  extend ProjectAdapter
  include Retirement
  include Houston::Props

  belongs_to :team

  before_validation :generate_default_slug, :set_default_color
  validates_presence_of :name, :slug, :color_name

  validates :slug, format: { with: /\A[a-z0-9_\-]+\z/ }

  default_scope { order(:name) }

  def to_param
    slug
  end

  def color
    Houston.config.project_colors[color_name]
  end



  def self.[](slug)
    find_by_slug(slug)
  end



  # Features
  # ------------------------------------------------------------------------- #

  def self.with_feature(feature)
    where ["? = ANY(projects.selected_features)", feature]
  end

  def features
    (Houston.config.project_features & selected_features) + [:settings]
  end

  def selected_features
    Array(super).map(&:to_sym)
  end

  def feature?(feature_slug)
    selected_features.member? feature_slug.to_sym
  end

  # ------------------------------------------------------------------------- #



  # Teammates
  # ------------------------------------------------------------------------- #

  Houston.config.roles.each do |role|
    method_name = role.downcase.gsub(" ", "_").pluralize

    class_eval <<-RUBY, __FILE__, __LINE__ + 1
    def #{method_name}
      return User.none if team.nil?
      team.#{method_name}
    end
    RUBY
  end

  def teammates
    return User.none if team.nil?
    team.users
  end

  # ------------------------------------------------------------------------- #



private

  def generate_default_slug
    self.slug = self.name.to_s.underscore.gsub("/", "-").dasherize.gsub(".", "").gsub(/\s+/, "_") unless slug
  end

  def set_default_color
    self.color_name = "default" unless color_name
  end

end
