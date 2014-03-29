class KanbanTicketPresenter < TicketPresenter

  def ticket_to_json(ticket)
    super.merge(queues: ticket.age_in_queues)
  end
  
end
