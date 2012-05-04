module TicketHelper
  
  def format_ticket(ticket)
    "[##{ticket.number}] #{format_with_feature_bolded ticket.summary}".html_safe
  end
  
  def link_to_ticket(ticket)
    if ticket.project
      link_to format_ticket(ticket), unfuddle_ticket_url(ticket)
    else
      format_ticket(ticket)
    end
  end
  
  def link_to_ticket_number(ticket)
    if ticket.project
      link_to "##{ticket.number}", unfuddle_ticket_url(ticket)
    else
      "##{ticket.number}"
    end
  end
  
end
