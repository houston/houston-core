class TicketAntecedent
  
  def initialize(kind, id)
    @kind = kind
    @id = id
  end
  
  attr_reader :kind, :id
  
  def self.from_s(string)
    new *string.split(":")
  end
  
  def to_s
    "#{kind}:#{id}"
  end
  
end
