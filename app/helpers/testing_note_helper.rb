module TestingNoteHelper
  
  def testing_note_badge_for_ticket(ticket)
    "<span class=\"testing-note-badge #{ticket.testing_status}\">#{ticket.testing_notes.count}</span>".html_safe
  end
  
end
