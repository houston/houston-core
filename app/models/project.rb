class Project < ActiveRecord::Base
  
  has_many :environments, :dependent => :destroy
  has_many :tickets, :dependent => :destroy
  
  accepts_nested_attributes_for :environments, :allow_destroy => true
  
  
  
  # Later, I hope to support multiple adapters
  # and make the ticket system choice either part
  # of the config.yml or a project's configuration.
  def ticket_system
    @unfuddle ||= Unfuddle.instance.project(unfuddle_id)
  end
  
  
  
  def in_development_query
    "#{kanban_field}-eq-#{development_id}"
  end
  
  def staged_for_testing_query
    "#{kanban_field}-eq-#{development_id}"
  end
  
  def in_testing_query
    "#{kanban_field}-eq-#{testing_id}"
  end
  
  def staged_for_release_query
    "#{kanban_field}-neq-#{production_id}"
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
  
  def find_tickets(*query)
    unfuddle_tickets = ticket_system.find_tickets(*query)
    unfuddle_tickets.map do |unfuddle_ticket|
      ticket = self.tickets.find_by_number(unfuddle_ticket["number"])
      if ticket
        ticket.update_attributes(Ticket.attributes_from_unfuddle_ticket(unfuddle_ticket))
      else
        ticket = self.tickets.create(Ticket.attributes_from_unfuddle_ticket(unfuddle_ticket))
      end
      ticket
    end
  end
  
  
  
  def tickets_in_queue(queue)
    queue = queue.slug if queue.is_a?(KanbanQueue)
    tickets = case queue.to_sym
    when :staged_for_development
      self.tickets.in_queue("staged_for_development")
    
    when :in_development
      find_tickets(in_development_query, :status => :accepted)
    
    when :staged_for_testing
      find_tickets(staged_for_testing_query, :status => :resolved)
    
    when :in_testing
      find_tickets(in_testing_query, :status => :resolved)
    
    when :staged_for_release
      find_tickets(staged_for_release_query, :status => :closed, :resolution => :fixed)
    
    when :last_release
      production = environments.find_by_slug("master") # <-- !todo: encode this special knowledge about 'master'
      last_release = production && production.releases.first
      last_release ? last_release.tickets : []
    end
    
    tickets.each { |ticket| ticket.queue = queue }
    tickets
  end
  
  
  
  def to_param
    slug
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
  
  
  
  def repo
    @repo ||= Grit::Repo.new(git_path)
  end
  
  
  
  def testers
    User.testers
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
