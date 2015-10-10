class TestingNote < ActiveRecord::Base

  before_create  :create_ticket_comment!
  before_update  :update_ticket_comment!
  before_destroy :destroy_ticket_comment!
  after_create { Houston.observer.fire "testing_note:create", self }
  after_update { Houston.observer.fire "testing_note:update", self }
  after_save   { Houston.observer.fire "testing_note:save", self }

  belongs_to :user
  belongs_to :ticket
  belongs_to :project

  VERDICTS = %w{works fails badticket none}

  validates :user, :presence => true
  validates :ticket, :presence => true
  validates :project, :presence => true
  validates :comment, :presence => true, :length => 1..1000
  validates :verdict, :presence => true, :inclusion => VERDICTS



  def to_comment
    TicketComment.new(
      user: user,
      body: "**#{verdict}** #{comment}",
      remote_id: remote_id )
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



private

  def create_ticket_comment!
    remote_id = ticket.create_comment!(to_comment)
    self.remote_id = remote_id
  end

  def update_ticket_comment!
    ticket.update_comment!(to_comment)
  end

  def destroy_ticket_comment!
    ticket.destroy_comment!(to_comment)
  end

end
