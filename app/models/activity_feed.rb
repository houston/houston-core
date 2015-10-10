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



  class Event < Struct.new(:time, :project)
    def date
      time.to_date
    end
  end

  class TicketEvent < Event
    attr_reader :ticket

    def initialize(time, ticket)
      @ticket = ticket
      super time, ticket.project
    end

    def actor
      ticket.reporter
    end
  end

  class TicketCreatedEvent < TicketEvent
    def initialize(ticket)
      super(ticket.created_at, ticket)
    end

    def css
      "timeline-event-ticket-created"
    end

    def icon
      "fa fa-plus"
    end
  end

  class TicketClosedEvent < TicketEvent
    def initialize(ticket)
      super(ticket.closed_at, ticket)
    end

    def resolution
      return "Closed" if ticket.resolution.blank?
      ticket.resolution.titleize
    end

    def css
      "timeline-event-ticket-closed"
    end

    def icon
      "fa fa-minus"
    end
  end

  class ReleaseEvent < Event
    attr_reader :release

    def initialize(release)
      @release = release
      super(release.created_at, release.project)
    end

    def css
      "timeline-event-release"
    end

    def icon
      "fa fa-paper-plane"
    end

    def actor
      release.user
    end
  end

end
