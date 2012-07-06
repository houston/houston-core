module TicketHelper
  
  def format_ticket(ticket)
    "[##{ticket.number}] #{format_with_feature_bolded ticket.summary}".html_safe
  end
  
  def link_to_ticket(ticket)
    contents = block_given? ? yield : format_ticket(ticket)
    if ticket.project
      link_to contents, unfuddle_ticket_url(ticket), target: "_blank"
    else
      contents
    end
  end
  
  def link_to_ticket_number(ticket)
    if ticket.project
      link_to "##{ticket.number}", unfuddle_ticket_url(ticket)
    else
      "##{ticket.number}"
    end
  end
  
  def attributes_for_ticket_verdict(ticket)
    attributes = {}
    ticket.verdicts_by_tester_index.each do |i, verdict|
      attributes["tester-#{i}"] = verdict
    end
    attributes.map { |key, value| "data-#{key}=\"#{value}\"" }.join(" ").html_safe
  end
  
  MINUTE = 60
  HOUR = MINUTE * 60
  DAY = HOUR = 24
  
  def format_duration(seconds)
    if seconds < HOUR
      minutes = (seconds / MINUTE).floor
      unit = minutes == 1 ? 'minute' : 'minutes'
      "#{minutes} #{unit}"
    elsif seconds < DAY
      hours = (seconds / HOUR).floor
      unit = hours == 1 ? 'hour' : 'hours'
      "#{hours} #{unit}"
    else
      days = (seconds / DAY).floor
      unit = days == 1 ? 'day' : 'days'
      "#{days} #{unit}"
    end
  end
  
  def class_for_age(seconds)
    if seconds < (2 * DAY)
      'young'
    elsif seconds < (7 * DAY)
      'adult'
    else
      'old'
    end
  end
  
end
