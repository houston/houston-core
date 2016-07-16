module Houston
  class TicketAntecedentSerializer

    def applies_to?(object)
      object.is_a?(TicketAntecedent)
    end

    def pack(antecedent)
      { "ticket_or_commit" => antecedent.ticket_or_commit,
        "kind" => antecedent.kind,
        "id" => antecedent.id }
    end

    def unpack(object)
      TicketAntecedent.new *object.values_at("ticket_or_commit", "kind", "id")
    end

  end
end

Houston.add_serializer Houston::TicketAntecedentSerializer.new
