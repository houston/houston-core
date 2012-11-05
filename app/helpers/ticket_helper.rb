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
  
  def format_with_feature_bolded(message)
    feature = (message.match(/^([^\{:]+):/) || [])[1]
    if feature
      message = h(message[feature.length..-1])
      feature = "<b>#{h feature}</b>"
    end
    "#{feature}#{message}".html_safe
  end
  
  
  
  def link_to_goldmine_case(number)
    link_to number, goldmine_case_number_url(number), target: "_blank"
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
  DAY = HOUR * 24
  
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
    if    seconds < 6.hours;        'infant'
    elsif seconds < 2.days;         'child'
    elsif seconds < 7.days;         'adult'
    elsif seconds < 4.weeks;        'senior'
    elsif seconds < 26.weeks;       'old'
    else                            'ancient'
    end
  end
  
end
