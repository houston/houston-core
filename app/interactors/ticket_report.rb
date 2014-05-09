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
      :closed_at)
    
    def antecedents
      (super || []).map { |s| TicketAntecedent.from_s(self, s) }
    end
  end
  
  def initialize(tickets)
    @tickets = tickets.joins(:reporter).order(Ticket.arel_table[:created_at].desc)
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
        :closed_at
      ).map { |args| ViewTicket.new(*args) }
  end
  
end
