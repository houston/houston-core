class FullTicketPresenter < TicketPresenter
  include MarkdownHelper

  def ticket_to_json(ticket)
    reporter = ticket.reporter
    super.merge(
      description: mdown(ticket.description),
      reporterEmail: reporter && reporter.email,
      reporterName: reporter && reporter.name)
  end

end
