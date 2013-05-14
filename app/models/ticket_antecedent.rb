class TicketAntecedent
  
  def initialize(ticket, kind, id)
    @ticket = ticket
    @kind = kind
    @id = id
  end
  
  attr_reader :ticket, :kind, :id
  delegate :project, to: :ticket
  
  def self.from_s(ticket, string)
    new ticket, *string.split(":")
  end
  
  def to_s
    "#{kind}:#{id}"
  end
  
end
