class FullTicketPresenter < TicketPresenter
  include MarkdownHelper

  def ticket_to_json(ticket)
    reporter = ticket.reporter
    super.merge(
      description: mdown(ticket.description),
      tasks: ticket.tasks.map { |task| task.ticket = ticket; {
        id: task.id,
        description: task.description,
        number: task.number,
        letter: task.letter,
        effort: task.effort } },
      reporter: reporter && {
        email: reporter.email,
        name: reporter.name })
  end

end
