class TicketCommitter < Struct.new(:name, :email)

  def tester?
    false
  end

  def to_h
    { name: name, email: email }
  end

end
