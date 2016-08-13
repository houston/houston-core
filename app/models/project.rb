class Project < ActiveRecord::Base
  extend ProjectAdapter
  include Retirement
  include FeatureState
  include Houston::Props

  belongs_to :team
  has_many :releases, dependent: :destroy
  has_many :commits, dependent: :destroy, extend: CommitSynchronizer
  has_many :tickets, dependent: :destroy, extend: TicketSynchronizer
  has_many :milestones, dependent: :destroy, extend: MilestoneSynchronizer
  has_many :uncompleted_milestones, -> { uncompleted }, class_name: "Milestone"
  has_many :test_runs, dependent: :destroy
  has_many :tests, dependent: :destroy
  has_many :deploys
  has_many :pull_requests, class_name: "Github::PullRequest"
  belongs_to :head, class_name: "Commit", foreign_key: "head_sha", primary_key: "sha"

  before_validation :generate_default_slug, :set_default_color
  validates_presence_of :name, :slug, :color



  has_adapter :TicketTracker,
              :VersionControl,
              :ErrorTracker,
              :CIServer



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

  def environments_with_release_notes
    environments.select(&method(:show_release_notes_for?))
  end

  def show_release_notes_for?(environment_name)
    props["releases.ignore.#{environment_name.downcase}"] != "1"
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
      return TeamUser.none if team.nil?
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





  # Ticket Tracking
  # ------------------------------------------------------------------------- #

  def ticket_tracker_project_url
    ticket_tracker.project_url
  end

  def ticket_tracker_ticket_url(ticket_number)
    ticket_tracker.ticket_url(ticket_number)
  end



  def create_ticket!(attributes)
    ticket = tickets.build attributes.merge(number: 0)
    ticket = tickets.create_from_remote ticket_tracker.create_ticket!(ticket) if ticket.valid?
    ticket
  end



  def find_or_create_tickets_by_number(*numbers)
    tickets.numbered(*numbers, sync: true)
  end

  def all_tickets
    tickets.fetch_all
  end

  def open_tickets
    tickets.fetch_open
  end

  def find_tickets(*query)
    tickets.fetch_with_query(*query)
  end



  def all_milestones
    milestones.fetch_all
  end

  def open_milestones
    milestones.fetch_open
  end

  def create_milestone!(attributes)
    milestone = milestones.build attributes
    if milestone.valid?
      if ticket_tracker.respond_to?(:create_milestone!)
        milestone = milestones.create(
          attributes.merge(
            ticket_tracker.create_milestone!(milestone).attributes))
      else
        milestone.save
      end
    end
    milestone
  end



  def ticket_tracker_sync_in_progress?
    ticket_tracker_sync_started_at.present? and ticket_tracker_sync_started_at > 5.minutes.ago
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





  # Error Tracker
  # ------------------------------------------------------------------------- #

  def error_tracker_project_url
    error_tracker.project_url
  end

  def error_tracker_error_url(error_id)
    error_tracker.error_url(error_id)
  end

  # ------------------------------------------------------------------------- #





  # Continuous Integration
  # ------------------------------------------------------------------------- #

  def ci_server_job_url
    ci_server.job_url
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
