class Commit < ActiveRecord::Base
  
  belongs_to :release
  has_and_belongs_to_many :tickets
  
  after_create :associate_tickets_with_self
  
  delegate :project, :to => :release
  
  def self.attributes_from_grit_commit(grit_commit)
    { :sha => grit_commit.sha,
      :message => grit_commit.message,
      :date => grit_commit.committed_date,
      :committer => grit_commit.author.name,
      :committer_email => grit_commit.author.email }
  end
  
  def ticket_numbers
    @ticket_numbers ||= message.scan(TICKET_PATTERN).flatten
  end
  
  def skip?
    ticket_numbers.any? || SKIP_PATTERNS.any? { |pattern| message =~ pattern }
  end
  
  def grit_commit
    project.repo.commit(sha)
  end
  
  
  
  TICKET_PATTERN = /\[#(\d+)\]/
  
  SKIP_PATTERNS = [
    /\[skip\]/,
    /\[testfix\]/,
    /\[refactor\]/,
    /^Merge (remote-tracking )?branch/
  ]
  
  
  
private
  
  
  
  def associate_tickets_with_self
    return if ticket_numbers.empty?
    
    project.find_or_create_tickets_by_number(ticket_numbers).each do |ticket|
      ticket.commits << self unless ticket.commits.exists?(id)
    end
  end
  
  
  
end
