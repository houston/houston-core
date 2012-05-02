class TestingNote < ActiveRecord::Base
  
  belongs_to :user
  belongs_to :ticket
  
  VERDICTS = %w{works fails}
  
  validates :user, :presence => true
  validates :ticket, :presence => true
  validates :comment, :presence => true, :length => 1..250
  validates :verdict, :presence => true, :inclusion => VERDICTS
  
  remote_model Unfuddle::Comment
  attr_remote :id => :unfuddle_id,
              :ticket_id => :unfuddle_ticket_id,
              :project_id => :unfuddle_project_id,
              :body => :unfuddle_comment_body
  remote_key [:project_id, :ticket_id, :id], :path => "/projects/:unfuddle_project_id/tickets/:unfuddle_ticket_id/comments/:unfuddle_id"
  expires_after 100.years
  
  delegate :project, :to => :ticket
  
  def unfuddle_ticket_id
    ticket.unfuddle_id
  end
  attr_writer :unfuddle_ticket_id
  
  def unfuddle_project_id
    project.unfuddle_id
  end
  attr_writer :unfuddle_project_id
  
  def unfuddle_comment_body
    "**#{verdict}** #{comment}"
  end
  
  def unfuddle_comment_body=(val)
    if val[/^\*\*works\*\* /]
      val[/^\*\*works\*\* /] = ""
      self.verdict = "works"
    elsif  val[/^\*\*fails\*\* /]
      val[/^\*\*fails\*\* /] = ""
      self.verdict = "fails"
    end
    self.comment = val
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
