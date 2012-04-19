module TicketHelper
  
  def format_ticket(ticket)
    "[##{ticket.number}] #{format_with_feature_bolded ticket.summary}".html_safe
  end
  
  def link_to_ticket(ticket)
    link_to format_ticket(ticket), unfuddle_ticket_url(ticket)
  end
  
end
