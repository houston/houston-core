Houston.config do
  on "testing_note:create" do |note|
    ticket, verdict = note.ticket, note.verdict
    ProjectNotification.testing_note(note, ticket.participants).deliver! if verdict == "none"
    ProjectNotification.testing_note(note, ticket.participants.reject(&:tester?)).deliver! if verdict == "fails"
  end
end
