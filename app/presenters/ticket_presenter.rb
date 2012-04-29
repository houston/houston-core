class TicketPresenter
  
  def initialize(tickets)
    @tickets = tickets
  end
  
  def as_json(*args)
    @tickets.map do |ticket|
      { projectId: ticket.project.unfuddle_id,
        projectSlug: ticket.project.slug,
        projectColor: ticket.project.color,
        number: ticket.number,
        summary: ticket.summary,
        age: ticket.age }
    end
  end
  
  def with_testing_notes
    @tickets.map do |ticket|
      { id: ticket.id,
        testingNotes: TestingNotePresenter.new(ticket.testing_notes).as_json,
        projectId: ticket.project.unfuddle_id,
        projectSlug: ticket.project.slug,
        projectColor: ticket.project.color,
        projectTesters: ticket.project.testers.map(&:id),
        number: ticket.number,
        summary: ticket.summary }
    end
  end
  
end
