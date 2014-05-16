class SprintTicketPresenter < TicketPresenter
  
  def ticket_to_json(ticket)
    super.merge(
      estimatedEffort: ticket.extended_attributes["estimated_effort"],
      sequence: ticket.extended_attributes["sequence"],
      firstReleaseAt: ticket.first_release_at,
      closedAt: ticket.closed_at,
      resolved: !ticket.resolution.blank?,
      checkedOutAt: ticket.checked_out_at,
      checkedOutBy: present_user(ticket.checked_out_by))
  end
  
private
  
  def present_user(user)
    return nil unless user
    { id: user.id,
      email: user.email,
      name: user.name }
  end
  
end
