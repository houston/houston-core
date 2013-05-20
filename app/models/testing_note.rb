class TestingNote < ActiveRecord::Base
  
  before_create  { ticket.create_comment! self }
  before_update  { ticket.update_comment! self }
  before_destroy { ticket.destroy_comment! self }
  after_create { Houston.observer.fire "testing_note:create", self }
  after_update { Houston.observer.fire "testing_note:update", self }
  after_save   { Houston.observer.fire "testing_note:save", self }
  
  belongs_to :user
  belongs_to :ticket
  belongs_to :project
  
  VERDICTS = %w{works fails none}
  
  validates :user, :presence => true
  validates :ticket, :presence => true
  validates :project, :presence => true
  validates :comment, :presence => true, :length => 1..1000
  validates :verdict, :presence => true, :inclusion => VERDICTS
  
  
  
  def to_comment
    TicketComment.new(
      user: user,
      body: "**#{verdict}** #{comment}",
      remote_id: unfuddle_id )
  end
  
  
  
  def pass?
    verdict == "works"
  end
  
  def fail?
    verdict == "fails"
  end
  
  def first_fail?
    return false unless fail?
    first_fail = ticket.testing_notes_since_last_release.where(verdict: "fails").order("created_at ASC").first
    first_fail == nil || first_fail.id == self.id
  end
  
end
