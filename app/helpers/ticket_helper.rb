module TicketHelper
  
  def format_ticket(ticket)
    "[##{ticket.number}] #{format_with_feature_bolded ticket.summary}".html_safe
  end
  
  def link_to_ticket(ticket)
    contents = block_given? ? yield : format_ticket(ticket)
    if ticket.project
      link_to contents, ticket.ticket_tracker_ticket_url, target: "_blank"
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
  
  
  
  def format_antecedent(antecedent)
    case antecedent.kind
    when "Goldmine"; "Goldmine #{link_to_goldmine_case(antecedent.id)}".html_safe
    when "Errbit"; "Err #{link_to_err(antecedent.id)}".html_safe
    end
  end
  
  def link_to_goldmine_case(number)
    link_to "##{number}", goldmine_case_number_url(number), target: "_blank"
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
      format_duration_with_units(seconds / MINUTE, 'minute')
    elsif seconds < DAY
      format_duration_with_units(seconds / HOUR, 'hour')
    else
      format_duration_with_units(seconds / DAY, 'day')
    end
  end
  
  def format_duration_with_units(quantity, unit)
    quantity = quantity.floor
    unit << 's' unless quantity == 1
    "#{quantity} #{unit}"
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
