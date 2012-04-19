class Commit < ActiveRecord::Base
  
  belongs_to :release
  
  delegate :project, :to => :release
  
  def self.attributes_from_grit_commit(grit_commit)
    { :sha => grit_commit.sha,
      :message => grit_commit.message,
      :date => grit_commit.committed_date,
      :committer => grit_commit.committer.name }
  end
  
  def ticket_numbers
    @ticket_numbers ||= message.scan(TICKET_PATTERN).flatten
  end
  
  def skip?
    ticket_numbers.any? || SKIP_PATTERNS.any? { |pattern| message =~ pattern }
  end
  
  
  
  TICKET_PATTERN = /\[#(\d+)\]/
  
  SKIP_PATTERNS = [
    /\[skip\]/,
    /\[testfix\]/,
    /\[refactor\]/,
    /^Merge branch/
  ]
  
end
