module TicketHelper

  def format_ticket(ticket)
    "<span class=\"ticket-number\">[##{ticket.number}]</span> <span class=\"ticket-summary\">#{format_with_feature_bolded ticket.summary}</span>".html_safe
  end

  def link_to_ticket(ticket)
    contents = block_given? ? yield : format_ticket(ticket)
    if ticket.project
      link_to contents, ticket.ticket_tracker_ticket_url, target: "_blank", rel: "ticket", "data-number" => ticket.number, "data-project" => ticket.project.slug
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
    when "Errbit"; "Errbit #{link_to_err(antecedent.project, antecedent.id)}".html_safe
    end
  end

  def link_to_goldmine_case(number)
    link_to "##{number}", goldmine_case_number_url(number), target: "_blank"
  end

end
