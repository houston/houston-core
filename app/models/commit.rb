class Commit < ActiveRecord::Base
  
  belongs_to :release
  
  def self.attributes_from_grit_commit(grit_commit)
    { :sha => grit_commit.sha,
      :message => grit_commit.message,
      :date => grit_commit.committed_date,
      :committer => grit_commit.committer.name }
  end
  
  
  def skip?
    SKIP_PATTERNS.any? { |pattern| message =~ pattern }
  end
  
  
  
  
  SKIP_PATTERNS = [
    /\[skip\]/,
    /\[testfix\]/,
    /\[refactor\]/
  ]
  
end
