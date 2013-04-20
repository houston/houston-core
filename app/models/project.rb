class Project < ActiveRecord::Base
  extend ProjectAdapter
  
  has_many :releases, :dependent => :destroy
  has_many :commits
  has_many :tickets, :dependent => :destroy
  has_many :testing_notes, :dependent => :destroy
  has_many :test_runs, :dependent => :destroy
  has_many :deploys
  has_many :roles, :dependent => :destroy
  
  accepts_nested_attributes_for :roles, :allow_destroy => true # <-- !todo: authorized access only
  
  
  has_adapter Houston::TicketTracker,   project_id: :ticket_tracker_id
  has_adapter Houston::VersionControl,  location: :version_control_location
  has_adapter Houston::ErrorTracker,    project_id: :error_tracker_id
  has_adapter Houston::CIServer
  
  
  default_scope order(:name)
  
  def last_test_run
    test_runs.order("created_at DESC").first
  end
  
  def to_param
    slug
  end
  
  def environment(environment_name)
    Environment.new(self, environment_name)
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
  
  def followers
    roles.to_users
  end
  
  Houston.roles.each do |role|
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
    
    unfuddle_tickets = ticket_tracker.find_tickets!(*query)
    tickets_from_unfuddle_tickets(unfuddle_tickets)
  end
  
  def tickets_from_unfuddle_tickets(unfuddle_tickets)
    return [] if unfuddle_tickets.empty?
    
    self.class.benchmark("[project.tickets_from_unfuddle_tickets] synchronizing with local tickets") do
      numbers = unfuddle_tickets.map(&:number)
      tickets = self.tickets.where(number: numbers).includes(:testing_notes).includes(:commits)
      
      unfuddle_tickets.reject(&:nil?).map do |unfuddle_ticket|
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
