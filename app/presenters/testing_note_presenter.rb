class TestingNotePresenter
  include AvatarHelper

  def initialize(testing_notes)
    @testing_notes = testing_notes
  end

  def as_json(*args)
    if @testing_notes.is_a?(TestingNote)
      to_hash @testing_notes
    else
      @testing_notes.map(&method(:to_hash))
    end
  end

  def to_hash(testing_note)
    { id: testing_note.id,
      createdAt: testing_note.created_at,
      avatarImage: avatar_for(testing_note.user),
      userId: testing_note.user_id,
      byTester: testing_note.user.try(:tester?),
      ticketId: testing_note.ticket_id,
      verdict: testing_note.verdict,
      comment: testing_note.comment }
  end

end
