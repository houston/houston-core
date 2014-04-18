class TicketPresenter
  include UrlHelper
  
  def initialize(tickets)
    @tickets = OneOrMany.new(tickets)
  end
  
  def as_json(*args)
    tickets = @tickets
    tickets = Houston.benchmark "[#{self.class.name.underscore}] Load objects" do
      tickets.load
    end if tickets.is_a?(ActiveRecord::Relation)
    Houston.benchmark "[#{self.class.name.underscore}] Prepare JSON" do
      tickets.map(&method(:ticket_to_json))
    end
  end
  
  def ticket_to_json(ticket)
    project = ticket.project
    { id: ticket.id,
      projectId: project.id,
      projectSlug: project.slug,
      projectTitle: project.name,
      projectColor: project.color,
      ticketSystem: project.ticket_tracker_name,
      ticketUrl: ticket.ticket_tracker_ticket_url,
      number: ticket.number,
      summary: ticket.summary,
      type: ticket.type.to_s.downcase.dasherize,
      tags: ticket.tags.map(&:to_h),
      extendedAttributes: ticket.extended_attributes }
  end
  
end
