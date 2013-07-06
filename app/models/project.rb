class Project < ActiveRecord::Base
  extend ProjectAdapter
  
  has_many :releases, :dependent => :destroy
  has_many :commits
  has_many :tickets, :dependent => :destroy, extend: TicketSynchronizer
  has_many :testing_notes, :dependent => :destroy
  has_many :test_runs, :dependent => :destroy
  has_many :deploys
  has_many :roles, :dependent => :destroy
  
  serialize :extended_attributes, ActiveRecord::Coders::Hstore
  
  accepts_nested_attributes_for :roles, :allow_destroy => true # <-- !todo: authorized access only
  
  
  
  has_adapter :TicketTracker,
              :VersionControl,
              :ErrorTracker,
              :CIServer
  
  
  default_scope order(:name)
  
  def last_test_run
    test_runs.order("created_at DESC").first
  end
  
  def to_param
    slug
  end
  
  def color_value
    Houston.config.project_colors[color]
  end
  
  def environment(environment_name)
    Environment.new(self, environment_name)
  end
  
  def extended_attributes
    super || (self.extended_attributes = {})
  end
  
  def testers
    User.testers
  end
  
  
  
  
  
  # Retirement
  # ------------------------------------------------------------------------- #
  
  default_scope where(retired_at: nil)
  
  def retire!
    update_attributes!(retired_at: Time.now)
    freeze
  end
  
  def unretire!
    update_attributes!(retired_at: nil)
  end
  
  # ------------------------------------------------------------------------- #  
  
  
  
  
  
  # Teammates
  # ------------------------------------------------------------------------- #
  
  def teammates
    roles.participants.to_users
  end
  
  Houston.config.project_roles.each do |role|
    method_name = role.downcase.gsub(' ', '_')
    collection_name = method_name.pluralize
    
    class_eval <<-RUBY
      def #{collection_name}
        @#{collection_name} ||= roles.#{collection_name}.to_users
      end
      
      def #{collection_name}_ids
        @#{collection_name}_ids ||= roles.#{collection_name}.to_users.reorder("").pluck(:id)
      end
    RUBY
  end
  
  def followers # <-- redefine followers to be everyone who participates in or follows the project
    roles.to_users
  end
  
  def add_teammate(user_or_id, role)
    attributes = {project: self, name: role}
    attributes[user_or_id.is_a?(User) ? :user : :user_id] = user_or_id
    roles.create!(attributes)
  end
  
  def is_teammate?(user_or_id)
    roles.for_user(user_or_id).any?
  end
  alias :teammate? :is_teammate?
  
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
    ticket = tickets.create ticket_tracker.create_ticket!(ticket).attributes if ticket.valid?
    ticket
  end
  
  
  
  def find_or_create_tickets_by_number(*numbers)
    numbers = numbers.flatten.map(&:to_i).uniq
    tickets = self.tickets.numbered(numbers)
    if tickets.length < numbers.length
      ticket_numbers = tickets.map(&:number)
      tickets.concat self.tickets.fetch_numbered(numbers - ticket_numbers)
    end
    tickets
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
  
  
  
  def tickets_in_queue(queue)
    queue = KanbanQueue.find_by_slug(queue) unless queue.is_a?(KanbanQueue)
    tickets.includes(:ticket_queue).fetch_with_query(*queue.query).tap do |tickets|
      update_tickets_in_queue(tickets, queue)
    end
  end
  
  def update_tickets_in_queue(tickets, queue)
    tickets.each { |ticket| ticket.queue = queue.slug }
    
    ids = tickets.map(&:id).compact
    tickets_removed_from_queue = self.tickets.includes(:ticket_queue).in_queue(queue)
    tickets_removed_from_queue = tickets_removed_from_queue.where(["NOT (tickets.id IN (?))", ids]) if ids.any?
    tickets_removed_from_queue.each { |ticket| ticket.queue = nil }
    
    tickets
  end
  
  # ------------------------------------------------------------------------- #
  
  
  
  
  
  # Version Control
  # ------------------------------------------------------------------------- #
  
  alias :repo :version_control
  
  def version_control_temp_path
    Rails.root.join("tmp", "#{slug}.git").to_s # <-- the .git here is misleading; could be any kind of VCS
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
  
  
  
  
  
  def platform
    @platform ||= begin
      if dependency_version("rails") then "rails"
      else ""
      end
    end
  end
  
  def database
    @database = guess_database unless defined?(@database)
    @database
  end
  
  def guess_database
    return nil unless can_determine_dependencies?
    return "Postgres" if dependency_version("pg")
    return "MySQL" if dependency_version("mysql") || dependency_version("mysql2")
    return "SQLite" if dependency_version("sqlite3")
    return "MongoDB" if dependency_version("mongoid")
    "None"
  end
  
  def dependency_version(dependency)
    spec = locked_gems.specs.find { |spec| spec.name == dependency } if locked_gems
    spec.version if spec
  end
  
  def can_determine_dependencies?
    !!locked_gems
  end
  
  def locked_gems
    @locked_gems = lockfile && Bundler::LockfileParser.new(lockfile) unless defined?(@locked_gems)
    @locked_gems
  end
  
  def lockfile
    @lockfile = read_file("Gemfile.lock")
    @lockfile
  end
  
  def read_file(path, options={})
    repo.read_file(path, options)
  end
  
  
  
end
