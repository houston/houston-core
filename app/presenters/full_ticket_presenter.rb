class FullTicketPresenter < TicketPresenter
  include MarkdownHelper

  def ticket_to_json(ticket)
    super.merge(description: mdown(ticket.description))
  end
  
end
