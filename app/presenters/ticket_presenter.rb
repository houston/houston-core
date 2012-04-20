class TicketPresenter
  
  def initialize(tickets)
    @tickets = tickets
  end
  
  def as_json(*args)
    @tickets.map do |ticket|
      { projectId: ticket.project.unfuddle_id,
        projectSlug: ticket.project.slug,
        projectColor: ticket.project.color,
        number: ticket.number,
        summary: ticket.summary,
        age: ticket.age }
    end
  end
  
end
