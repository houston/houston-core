class FullTicketPresenter < TicketPresenter
  attr_reader :ability

  delegate :can?, to: :ability

  def initialize(ability, tickets)
    @ability = ability
    super tickets
  end

  def ticket_to_json(ticket)
    reporter = ticket.reporter
    super.merge(
      permissions: {
        update: can?(:update, ticket),
        destroy: can?(:destroy, ticket) },
      description: ticket.description,
      changes: present_versions(ticket.tasks.versions.includes(:versioned) + ticket.versions),
      tasks: ticket.tasks.map { |task| task.ticket = ticket; {
        id: task.id,
        description: task.description,
        number: task.number,
        letter: task.letter,
        effort: task.effort } },
      reporter: reporter && {
        email: reporter.email,
        name: reporter.name })
  end

private

  def present_versions(versions)
    versions.sort_by { |version| version.created_at }.reverse.map  { |version| {
      time: version.created_at,
      actor: present_version_actor(version.user),
      description: present_version_description(version)
    }}
  end

  def present_version_actor(actor)
    case actor
    when User then { name: actor.name, email: actor.email }
    when String then { name: actor }
    when nil then { name: "Unknown" }
    else raise NotImplementedError, "I don't know how to handle an actor of class #{actor.class}"
    end
  end

  def present_version_description(version)
    if version.changes.empty?
      "<b>added</b> a task: <em>#{version.versioned.letter}. #{version.versioned.description}</em>"
    else
      version.changes
        .map { |attribute, change| present_version_change(version, attribute, change) }
        .compact
        .join("<br />")
    end
  end

  def present_version_change(version, attribute, change)
    case attribute
    when "description" then "changed <b>Description</b>"
    when "summary" then "changed <b>Summary</b> from <em>#{change[0]}</em> to <em>#{change[1]}</em>"
    when "closed_at" then
      if change[0] && !change[1]
        "<b>reopened</b> the ticket"
      elsif change[1] && !change[0]
        "<b>closed</b> the ticket"
      else
        nil
      end
    when "effort" then
      if change[0] && change[1]
        if change[1] > change[0]
          "increased the <b>Effort</b> of task <b>#{version.versioned.letter}.</b> from <em>#{change[0]}</em> to <em>#{change[1]}</em>"
        else
          "decreased the <b>Effort</b> of task <b>#{version.versioned.letter}.</b> from <em>#{change[0]}</em> to <em>#{change[1]}</em>"
        end
      elsif change[1]
        "estimated the <b>Effort</b> of task <b>#{version.versioned.letter}.</b> at <em>#{change[1]}</em>"
      elsif change[0]
        "cleared the <b>Effort</b> of task <b>#{version.versioned.letter}.</b></em>"
      end
    else
      "changed <b>#{attribute.titleize}</b>"
    end
  end

end
