class TicketReport

  class ViewTicket < Struct.new(
      :id,
      :number,
      :type,
      :summary,
      :reporter_email,
      :reporter_first_name,
      :reporter_last_name,
      :antecedents,
      :opened_at,
      :closed_at,
      :milestone_id,
      :milestone_name)

    def antecedents
      (super || []).map { |s| TicketAntecedent.from_s(self, s) }
    end

    def reporter_name
      "#{reporter_first_name} #{reporter_last_name}"
    end

    def as_json(options={})
      { id: id,
        number: number,
        type: type.downcase,
        summary: summary,
        reporter: {
          email: reporter_email,
          name: reporter_name },
        milestone: milestone_id && {
          id: milestone_id,
          name: milestone_name },
        antecedents: antecedents.map { |antecedent| { id: antecedent.id, kind: antecedent.kind } },
        openedAt: opened_at,
        closedAt: closed_at }
    end
  end

  def initialize(tickets)
    @tickets = tickets
      .joins("LEFT OUTER JOIN users ON tickets.reporter_id=users.id")
      .joins("LEFT OUTER JOIN milestones ON tickets.milestone_id=milestones.id")
      .order(Ticket.arel_table[:created_at].desc)
  end

  def to_a
    @tickets.pluck(
        :id,
        :number,
        :type,
        :summary,
        "users.email",
        "users.first_name",
        "users.last_name",
        :antecedents,
        :created_at,
        :closed_at,
        "milestones.id",
        "milestones.name"
      ).map { |args| ViewTicket.new(*args) }
  end

end
