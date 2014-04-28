class TicketAntecedent
  include Comparable
  
  def initialize(ticket_or_commit, kind, id)
    @ticket_or_commit = ticket_or_commit
    @kind = kind
    @id = id
  end
  
  attr_reader :ticket_or_commit, :kind, :id
  delegate :project, to: :ticket_or_commit
  
  def self.from_s(ticket, string)
    new ticket, *string.split(":")
  end
  
  def to_s
    "#{kind}:#{id}"
  end
  
  def <=>(other)
    [kind, id] <=> [other.kind, other.id]
  end
  
  
  
  def release!(release=nil)
    Houston.observer.fire "antecedent:#{kind.downcase.underscore}:released", self
  end
  
  def resolve!
    Houston.observer.fire "antecedent:#{kind.downcase.underscore}:resolved", self
  end
  
  def close!
    Houston.observer.fire "antecedent:#{kind.downcase.underscore}:closed", self
  end
  
end
