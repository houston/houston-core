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
  
  def grit_commit
    project.repo.commit(sha)
  end
  
  
  
  def skip?
    merge? || tags.member?("skip")
  end
  
  def merge?
    message =~ MERGE_COMMIT_PATTERN
  end
  
  
  
  def tags
    parsed_message[:tags]
  end
  
  def clean_message
    parsed_message[:clean_message]
  end
  
  def ticket_numbers
    parsed_message[:tickets]
  end
  
  def extra_attributes
    parsed_message[:attributes]
  end
  
  
  
  TICKET_PATTERN = /\[#(\d+)\]/
  
  EXTRA_ATTRIBUTE_PATTERN = /\{\{([^:\}]+):([^\}]+)\}\}/
  
  TAG_PATTERN = /^\s*\[([^\]]+)\]\s*/
  
  MERGE_COMMIT_PATTERN = /^Merge (remote-tracking )?branch/
  
  
  
private
  
  
  
  def parsed_message
    @parsed_message ||= parse_message!
  end
  
  def parse_message!
    tags = []
    tickets = []
    attributes = {}
    clean_message = message.dup
    
    clean_message.gsub!(TICKET_PATTERN) { tickets << $1; "" }
    clean_message.gsub!(EXTRA_ATTRIBUTE_PATTERN) { (attributes[$1] ||= []).push($2); "" }
    while clean_message.gsub!(TAG_PATTERN) { tags << $1; "" }; end
    
    {tags: tags, tickets: tickets, attributes: attributes, clean_message: clean_message.strip}
  end
  
  
  
  def associate_tickets_with_self
    return if ticket_numbers.empty?
    
    project.find_or_create_tickets_by_number(ticket_numbers).each do |ticket|
      ticket.commits << self unless ticket.commits.exists?(id)
    end
  end
  
  
  
end
