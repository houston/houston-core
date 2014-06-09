class TicketReport
  
  class ViewTicket < Struct.new(
      :id,
      :number,
      :type,
      :summary,
      :reporter_email,
      :reporter_name,
      :antecedents,
      :opened_at,
      :closed_at,
      :effort)
    
    def antecedents
      (super || []).map { |s| TicketAntecedent.from_s(self, s) }
    end
    
    def as_json(options={})
      { id: id,
        number: number,
        type: type.downcase,
        summary: summary,
        reporter: {
          email: reporter_email,
          name: reporter_name },
        effort: effort,
        antecedents: antecedents.map { |antecedent| { id: antecedent.id, kind: antecedent.kind } },
        openedAt: opened_at,
        closedAt: closed_at }
    end
  end
  
  def initialize(tickets)
    @tickets = tickets
      .joins("LEFT OUTER JOIN users ON tickets.reporter_id=users.id")
      .joins("LEFT OUTER JOIN tasks ON tasks.ticket_id=tickets.id")
      .group("tickets.id", "tickets.number", :type, :summary, "users.email", "users.name", :antecedents, "tickets.created_at", :closed_at)
      .order(Ticket.arel_table[:created_at].desc)
  end
  
  def to_a
    @tickets.pluck(
        :id,
        :number,
        :type,
        :summary,
        "users.email",
        "users.name",
        :antecedents,
        :created_at,
        :closed_at,
        "SUM(tasks.effort)"
      ).map { |args| ViewTicket.new(*args) }
  end
  
end
