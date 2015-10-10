class TicketComment

  def initialize(attributes={})
    @attributes = attributes
  end

  attr_reader :attributes

  def user
    attributes[:user]
  end

  def remote_id
    attributes[:remote_id]
  end

  def body
    attributes[:body]
  end

end
