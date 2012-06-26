require 'unfuddle/neq'


class Project < ActiveRecord::Base
  
  serialize :cached_queries
  
  has_many :environments, :dependent => :destroy
  has_many :tickets, :dependent => :destroy
  
  accepts_nested_attributes_for :environments, :allow_destroy => true
  
  
  
  # Later, I hope to support multiple adapters
  # and make the ticket system choice either part
  # of the config.yml or a project's configuration.
  def ticket_system
    @unfuddle ||= Unfuddle.instance.project(unfuddle_id)
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
        tickets.concat find_tickets(:number => numbers_to_fetch)
      end
    end
    tickets
  end
  
  def find_or_create_ticket_by_number(number)
    find_or_create_tickets_by_number(number).first
  end
  
  def find_tickets(*query)
    Rails.logger.info "[project.find_tickets] query: #{query.inspect}"
    
    unfuddle_tickets = ticket_system.find_tickets(*query)
    numbers = unfuddle_tickets.map { |unfuddle_ticket| unfuddle_ticket["number"] }
    tickets = self.tickets.where(number: numbers).includes(:testing_notes)
    
    unfuddle_tickets.map do |unfuddle_ticket|
      ticket = tickets.detect { |ticket| ticket.number == unfuddle_ticket["number"] }
      attributes = Ticket.attributes_from_unfuddle_ticket(unfuddle_ticket)
      if ticket
        
        # This is essentially a call to update_attributes,
        # but I broke it down so that we don't begin a
        # transaction if we don't have any changes to save.
        # This is pretty much just to reduce log verbosity.
        ticket.assign_attributes(attributes)
        ticket.save if ticket.changed?
      else
        ticket = self.tickets.create(attributes)
      end
      
      # There's no reason why this shouldn't be set,
      # but in order to reduce a bunch of useless hits
      # to the cache and a bunch of log output...
      ticket.project = self
      ticket
    end
  end
  
  
  
  def tickets_in_queue(queue)
    queue = KanbanQueue.find_by_slug(queue) unless queue.is_a?(KanbanQueue)
    
    if queue.local_query?
      self.tickets.in_queue(queue.slug)
    else
      query = construct_ticket_query_for_queue(queue)
      find_tickets(query).tap do |tickets|
        update_tickets_in_queue(tickets, queue)
      end
    end
  end
  
  def construct_ticket_query_for_queue(queue)
    query = (self.cached_queries ||= {})[queue.slug]
    
    unless query
      query = self.cached_queries[queue.slug] = ticket_system.construct_ticket_query(queue.query)
      save
    end
    
    query
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
  
  def number_of_slots
    5
  end
  
  def git_path
    @git_path ||= get_local_git_path
  end
  
  def git_uri
    @git_uri ||= Addressable::URI.parse(git_url)
  end
  
  def temp_path
    @temp_path ||= Rails.root.join("tmp", slug).to_s
  end
  
  def git_url_valid?
    !git_url.blank?
  end
  
  
  
  def repo
    @repo ||= Grit::Repo.new(git_path)
  end
  
  
  
  def testers
    @testers ||= User.testers
  end
  
  
  
private
  
  
  
  # Git repositories can be located on the local
  # machine (e.g. /path/to/repo) or they can be
  # located on remotely (e.g. git@host:repo.git).
  #
  # If the repo is local, we don't need to check
  # out a copy. If it is remote, we want to clone
  # it to a temp folder and then manipulate it.
  #
  def get_local_git_path
    if git_uri.absolute?
      get_local_copy_of_project!
      temp_path
    else
      git_uri
    end
  end
  
  def get_local_copy_of_project!
    if File.exists?(temp_path)
      git_pull!
    else
      git_clone!
    end
  end
  
  def git_pull!
    `cd "#{temp_path}" && git pull`
  end
  
  def git_clone!
    `cd "#{Rails.root.join("tmp").to_s}" && git clone #{git_url} ./#{slug}`
  end
  
  
  
end
