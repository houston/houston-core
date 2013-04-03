class Project < ActiveRecord::Base
  
  has_many :releases, :dependent => :destroy
  has_many :tickets, :dependent => :destroy
  has_many :test_runs, :dependent => :destroy
  has_many :notifications, :class_name => "UserNotification"
  has_many :deploys
  has_and_belongs_to_many :maintainers, :join_table => "projects_maintainers", :class_name => "User"
  
  after_create :save_default_notifications
  
  validate :ticket_tracking_id_is_valid
  validate :version_control_location_is_valid
  
  default_scope order(:name)
  
  def last_test_run
    test_runs.order("created_at DESC").first
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
  
  
  
  
  def find_or_create_tickets_by_number(*numbers)
    numbers = numbers.flatten.map(&:to_i).uniq
    tickets = self.tickets.numbered(numbers)
    if tickets.length < numbers.length
      ticket_numbers = tickets.map(&:number)
      numbers_to_fetch = numbers - ticket_numbers
      
      # Unfuddle will return all tickets if we fetch
      # tickets by number with no numbers given.
      if numbers_to_fetch.any?
        begin
          tickets.concat find_tickets(:number => numbers_to_fetch)
        rescue Unfuddle::Error
          # We couldn't fetch remote tickets, let's just return what we've got for now
        end
      end
    end
    tickets
  end
  
  def find_or_create_ticket_by_number(number)
    find_or_create_tickets_by_number(number).first
  end
  
  def find_tickets(*query)
    Rails.logger.info "[project.find_tickets] query: #{query.inspect}"
    
    unfuddle_tickets = ticket_system.find_tickets!(*query)
    tickets_from_unfuddle_tickets(unfuddle_tickets)
  end
  
  def tickets_from_unfuddle_tickets(unfuddle_tickets)
    return [] if unfuddle_tickets.empty?
    
    self.class.benchmark("[project.tickets_from_unfuddle_tickets] synchronizing with local tickets") do
      numbers = unfuddle_tickets.map(&:number)
      tickets = self.tickets.where(number: numbers).includes(:testing_notes).includes(:commits)
      
      unfuddle_tickets.map do |unfuddle_ticket|
        ticket = tickets.detect { |ticket| ticket.number == unfuddle_ticket.number }
        attributes = unfuddle_ticket.attributes
        if ticket
          
          # This is essentially a call to update_attributes,
          # but I broke it down so that we don't begin a
          # transaction if we don't have any changes to save.
          # This is pretty much just to reduce log verbosity.
          ticket.assign_attributes(attributes)
          
          # hstore thinks it has always changed
          has_legitimate_changes = ticket.changed?
          if has_legitimate_changes && ticket.changed == %w{extended_attributes}
            before, after = ticket.changes["extended_attributes"]
            has_legitimate_changes = false if before == after
          end
          ticket.save if has_legitimate_changes
        else
          ticket = Ticket.nosync { self.tickets.create(attributes) }
        end
        
        # There's no reason why this shouldn't be set,
        # but in order to reduce a bunch of useless hits
        # to the cache and a bunch of log output...
        ticket.project = self
        ticket
      end
    end
  end
  
  
  
  def tickets_in_queue(queue)
    queue = KanbanQueue.find_by_slug(queue) unless queue.is_a?(KanbanQueue)
    find_tickets(*queue.query).tap do |tickets|
      update_tickets_in_queue(tickets, queue)
    end
  end
  
  def update_tickets_in_queue(tickets, queue)
    tickets.each { |ticket| ticket.queue = queue.slug }
    
    ids = tickets.map(&:id).compact
    tickets_removed_from_queue = self.tickets.in_queue(queue)
    tickets_removed_from_queue = tickets_removed_from_queue.where(["NOT (tickets.id IN (?))", ids]) if ids.any?
    tickets_removed_from_queue.each { |ticket| ticket.queue = nil }
    
    tickets
  end
  
  
  
  
  
  def to_param
    slug
  end
  
  
  
  
  
  # Ticket Tracking
  # ------------------------------------------------------------------------- #
  
  def self.with_ticket_tracking
    where Project.arel_table[:ticket_tracking_adapter].not_eq("None")
  end
  
  def ticket_tracking_id_is_valid
    ticket_tracking_system.problems_with_project_id(ticket_tracking_id).each do |message|
      errors.add :ticket_tracking_id, message
    end
  end
  
  def ticket_system_project_url
    ticket_system.project_url
  end
  
  def ticket_system_ticket_url(ticket_number)
    ticket_system.ticket_url(ticket_number)
  end
  
  def ticket_system
    @ticket_system ||= ticket_tracking_system.create_connection(ticket_tracking_id)
  end
  
  def ticket_tracking_system
    Houston::TicketTracking.adapter(ticket_tracking_adapter)
  end
  
  # ------------------------------------------------------------------------- #  
  
  
  
  
  
  # Version Control
  # ------------------------------------------------------------------------- #
  
  def self.with_version_control
    where Project.arel_table[:version_control_adapter].not_eq("None")
  end
  
  def version_control_location_is_valid
    version_control_system.problems_with_location(
      version_control_location,
      version_control_temp_path).each do |message|
      errors.add :version_control_location, message
    end
  end
  
  def repo
    @repo ||= version_control_system.create_repo(
      version_control_location,
      version_control_temp_path)
  end
  
  def version_control_system
    Houston::VersionControl.adapter(version_control_adapter)
  end
  
  def version_control_temp_path
    Rails.root.join("tmp", "#{slug}.git").to_s # <-- the .git here is misleading; could be any kind of VCS
  end
  
  # ------------------------------------------------------------------------- #
  
  
  
  
  
  # Continuous Integration
  # ------------------------------------------------------------------------- #
  
  def self.with_ci_server
    where Project.arel_table[:ci_adapter].not_eq("None")
  end
  
  def ci_job
    @ci_job ||= ci_server.job_for_project(self)
  end
  
  def ci_server
    Houston::CI.adapter(ci_adapter)
  end
  
  # ------------------------------------------------------------------------- #
  
  
  
  
  
  def testers
    @testers ||= User.testers
  end
  
  
  
  def notifications_pairs=(pairs)
    self.notifications = pairs.map do |pair|
      user_id, environment = pair.split(",")
      find_or_create_notification(user_id: user_id.to_i, environment_name: environment)
    end
  end
  
  
  
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
    return "Postgres" if dependency_version("pg")
    return "MySQL" if dependency_version("mysql") || dependency_version("mysql2")
    return "SQLite" if dependency_version("sqlite3")
    return "MongoDB" if dependency_version("mongoid")
    nil
  end
  
  def dependency_version(dependency)
    spec = locked_gems.specs.find { |spec| spec.name == dependency } if locked_gems
    spec.version if spec
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
  
  
  
  def environment(environment_name)
    Environment.new(self, environment_name)
  end
  
  
  
private
  
  
  
  def save_default_notifications
    User.all.each do |user|
      environments = user.default_notifications_environments
      environments.each do |environment|
        self.notifications.push find_or_create_notification(user_id: user.id, environment_name: environment)
      end
    end
  end
  
  def find_or_create_notification(attributes)
    UserNotification.find_or_create(attributes.merge(project_id: id))
  end
  
  
  
end
