class ActivityFeed
  
  def initialize(projects, time, options={})
    @projects = projects
    @time = time
    @count = options.fetch(:count, 25)
  end
  
  attr_reader :projects, :time, :count
  
  def events
    @events ||= (
      ticket_creations +
      ticket_closures +
      releases)
        .sort_by(&:time)
        .reverse
        .take(count)
  end
  
  def ticket_creations
    Ticket.for_projects(projects).includes(:project, :reporter).created_before(time).limit(count)
      .map { |ticket| TicketCreatedEvent.new(ticket) }
  end
  
  def ticket_closures
    Ticket.for_projects(projects).includes(:project, :reporter).closed_before(time).limit(count)
      .map { |ticket| TicketClosedEvent.new(ticket) }
  end
  
  def releases
    Release.for_projects(projects).includes(:project, :user).before(time).limit(count)
      .map { |release| ReleaseEvent.new(release) }
  end
  
  
  
  TicketCreatedEvent = Struct.new(:time, :ticket) do
    def initialize(ticket)
      super(ticket.created_at, ticket)
    end
    
    def date
      time.to_date
    end
    
    def css
      "timeline-event-ticket-created"
    end
    
    def icon
      "icon-plus"
    end
    
    def actor
      ticket.reporter
    end
    
    delegate :project, to: :ticket
  end
  
  TicketClosedEvent = Struct.new(:time, :ticket) do
    def initialize(ticket)
      super(ticket.closed_at, ticket)
    end
    
    def date
      time.to_date
    end
    
    def css
      "timeline-event-ticket-closed"
    end
    
    def icon
      "icon-minus"
    end
    
    def actor
      ticket.reporter
    end
    
    delegate :project, to: :ticket
  end
  
  ReleaseEvent = Struct.new(:time, :release) do
    def initialize(release)
      super(release.created_at, release)
    end
    
    def date
      time.to_date
    end
    
    def css
      "timeline-event-release"
    end
    
    def icon
      "icon-rocket"
    end
    
    def actor
      release.user
    end
    
    delegate :project, to: :release
  end
  
end
