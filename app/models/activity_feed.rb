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
    Ticket.for_projects(projects).includes(:project).created_before(time).limit(count)
      .map { |ticket| TicketCreatedEvent.new(ticket) }
  end
  
  def ticket_closures
    Ticket.for_projects(projects).includes(:project).closed_before(time).limit(count)
      .map { |ticket| TicketClosedEvent.new(ticket) }
  end
  
  def releases
    Release.for_projects(projects).includes(:project).before(time).limit(count)
      .map { |release| ReleaseEvent.new(release) }
  end
  
  
  
  TicketCreatedEvent = Struct.new(:time, :ticket) do
    def initialize(ticket)
      super(ticket.created_at, ticket)
    end
    
    def date
      time.to_date
    end
    
    def to_partial_path
      "activity/ticket_created"
    end
  end
  
  TicketClosedEvent = Struct.new(:time, :ticket) do
    def initialize(ticket)
      super(ticket.closed_at, ticket)
    end
    
    def date
      time.to_date
    end
    
    def to_partial_path
      "activity/ticket_closed"
    end
  end
  
  ReleaseEvent = Struct.new(:time, :release) do
    def initialize(release)
      super(release.created_at, release)
    end
    
    def date
      time.to_date
    end
    
    def to_partial_path
      "activity/release"
    end
  end
  
end
