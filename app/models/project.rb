class Project < ActiveRecord::Base
  extend ProjectAdapter
  include Retirement
  include Houston::Props

  belongs_to :team
  has_many :commits, dependent: :destroy, extend: CommitSynchronizer
  has_many :deploys
  has_many :pull_requests, class_name: "Github::PullRequest"
  belongs_to :head, class_name: "Commit", foreign_key: "head_sha", primary_key: "sha"

  before_validation :generate_default_slug, :set_default_color
  validates_presence_of :name, :slug, :color

  validates :slug, format: { with: /\A[a-z0-9_\-]+\z/ }



  has_adapter :VersionControl



  default_scope { order(:name) }

  def to_param
    slug
  end

  def color_value
    Houston.config.project_colors[color]
  end



  def environments
    @environments ||= deploys.environments.map(&:downcase).uniq
  end

  def environment(environment_name)
    Environment.new(self, environment_name)
  end



  def extended_attributes
    raise NotImplementedError, "This feature has been deprecated; use props"
  end

  def extended_attributes=(value)
    raise NotImplementedError, "This feature has been deprecated; use props"
  end

  def view_options
    raise NotImplementedError, "This feature has been deprecated; use props"
  end

  def view_options=(value)
    raise NotImplementedError, "This feature has been deprecated; use props"
  end



  def self.[](slug)
    find_by_slug(slug)
  end



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

  def followers # <-- redefine followers to be everyone who participates in or follows the project
    puts "DEPRECATED: Project#followers is deprecated; use Project#teammates instead"
    teammates
  end

  # ------------------------------------------------------------------------- #





  # Version Control
  # ------------------------------------------------------------------------- #

  alias :repo :version_control

  def version_control_temp_path
    Houston.root.join("tmp", "#{slug}.git").to_s # <-- the .git here is misleading; could be any kind of VCS
  end

  def find_commit_by_sha(sha)
    commits.find_or_create_by_sha(sha)
  end

  def read_file(path, options={})
    repo.read_file(path, options)
  end

  def on_github?
    repo.is_a? Houston::Adapters::VersionControl::GitAdapter::GithubRepo
  end

  # ------------------------------------------------------------------------- #





private

  def generate_default_slug
    self.slug = self.name.to_s.underscore.gsub("/", "-").dasherize.gsub(".", "").gsub(/\s+/, "_") unless slug
  end

  def set_default_color
    self.color = "default" unless color
  end

end
