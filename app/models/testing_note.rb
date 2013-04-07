class TestingNote < ActiveRecord::Base
  
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
  
  remote_model Unfuddle::Comment
  attr_remote :id => :unfuddle_id,
              :ticket_id => :unfuddle_ticket_id,
              :project_id => :unfuddle_project_id,
              :body => :unfuddle_comment_body
  remote_key [:project_id, :ticket_id, :id], :path => "/projects/:unfuddle_project_id/tickets/:unfuddle_ticket_id/comments/:unfuddle_id"
  expires_after 100.years
  
  def unfuddle_ticket_id
    ticket.remote_id
  end
  attr_writer :unfuddle_ticket_id
  
  def unfuddle_project_id
    project.ticket_tracking_id
  end
  attr_writer :unfuddle_project_id
  
  def unfuddle_comment_body
    "**#{verdict}** #{comment}"
  end
  
  def unfuddle_comment_body=(val)
    VERDICTS.each do |_verdict|
      if val[/^\*\*#{_verdict}\*\* /]
        val[/^\*\*#{_verdict}\*\* /] = ""
        self.verdict = _verdict
      end
    end
    self.comment = val
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
  
  
  # !Override fetch_remote_resource, when this is fetched, set its prefix_options
  def fetch_remote_resource
    super.tap do |resource|
      resource.prefix_options = {project_id: unfuddle_project_id, ticket_id: unfuddle_ticket_id} if resource
    end
  end
  
  def nosync?
    super || (persisted? && unfuddle_id.blank?)
  end
  
  def any_remote_changes?
    super || comment_changed?
  end
  
  def local_attribute_changed?(name)
    if name == :unfuddle_comment_body
      comment_changed?
    else
      super(name)
    end
  end
  
  
  
end
