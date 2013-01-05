require 'unfuddle/neq'


class Project < ActiveRecord::Base
  
  serialize :cached_queries
  
  has_many :releases, :dependent => :destroy
  has_many :tickets, :dependent => :destroy
  has_many :test_runs, :dependent => :destroy
  has_many :notifications, :class_name => "UserNotification"
  has_and_belongs_to_many :maintainers, :join_table => "projects_maintainers", :class_name => "User"
  
  after_create :save_default_notifications
  
  validate :ticket_tracking_id_is_valid
  validate :version_control_location_is_valid
  
  default_scope order(:name)
  
  
  
  
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
        rescue SocketError # !todo: replace this with a custom error that represents all remote failures
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
      numbers = unfuddle_tickets.map { |unfuddle_ticket| unfuddle_ticket["number"] }
      tickets = self.tickets.where(number: numbers).includes(:testing_notes).includes(:commits)
      
      unfuddle_tickets.map do |unfuddle_ticket|
        ticket = tickets.detect { |ticket| ticket.number == unfuddle_ticket["number"] }
        attributes = ticket_attributes_from_unfuddle_ticket(unfuddle_ticket)
        if ticket
          
          # This is essentially a call to update_attributes,
          # but I broke it down so that we don't begin a
          # transaction if we don't have any changes to save.
          # This is pretty much just to reduce log verbosity.
          ticket.assign_attributes(attributes)
          ticket.save if ticket.changed?
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
  
  def ticket_attributes_from_unfuddle_ticket(unfuddle_ticket)
    attributes = Ticket.attributes_from_unfuddle_ticket(unfuddle_ticket)
    attributes.merge(
      "deployment" => get_custom_ticket_attribute(unfuddle_ticket, "Fixed in"),
      "goldmine" => get_custom_ticket_attribute(unfuddle_ticket, "Goldmine")
    )
  end
  
  def get_custom_ticket_attribute(unfuddle_ticket, custom_field_name)
    retried_once = false
    begin
      custom_field_key = custom_field_name.underscore.gsub(/\s/, "_")
      
      key = find_in_cache_or_execute("#{custom_field_key}_field") do
        ticket_system.get_ticket_attribute_for_custom_value_named!(custom_field_name) rescue "undefined"
      end
      
      value_id = unfuddle_ticket[key]
      return nil if value_id.blank?
      find_in_cache_or_execute("#{custom_field_key}_value_#{value_id}") do
        ticket_system.find_custom_field_value_by_id!(custom_field_name, value_id).value
      end
    rescue
      if retried_once
        raise
      else
        
        # If an error occurred above, it may be because
        # we cached the wrong value for something.
        retried_once = true
        invalidate_cache!("#{custom_field_key}_field", "#{custom_field_key}_value_#{value_id}")
        retry
      end
    end
  end
  
  
  
  def tickets_in_queue(queue)
    queue = KanbanQueue.find_by_slug(queue) unless queue.is_a?(KanbanQueue)
    query = construct_ticket_query_for_queue(queue)
    find_tickets(query).tap do |tickets|
      update_tickets_in_queue(tickets, queue)
    end
  end
  
  def construct_ticket_query_for_queue(queue)
    key = "#{queue.slug}-#{Digest::MD5::hexdigest(queue.query.inspect)}"
    find_in_cache_or_execute(key) { ticket_system.construct_ticket_query(queue.query) }
  # !todo: rescue from Houston::TicketTracking::InvalidQueryError with ... ?
  end
  
  def invalidate_cache!(*keys)
    keys.flatten.each do |key|
      self.cached_queries[key] = nil
    end
    save
  end
  
  def find_in_cache_or_execute(key)
    raise ArgumentError unless block_given?
    key = key.to_s
    
    value = (self.cached_queries ||= {})[key]
    unless value
      value = self.cached_queries[key] = yield
      save
    end
    value
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
  
  def dependency_version(dependency)
    return nil unless repo
    
    lockfile = repo.read_file("Gemfile.lock")
    return nil unless lockfile
    
    lockfile_contents = lockfile.data
    locked_gems = Bundler::LockfileParser.new(lockfile_contents)
    locked_gems.specs.find { |spec| spec.name == dependency }
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
