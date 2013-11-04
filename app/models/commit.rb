class Commit < ActiveRecord::Base
  
  belongs_to :project
  has_and_belongs_to_many :committers, class_name: "User"
  has_and_belongs_to_many :releases
  has_and_belongs_to_many :tickets
  
  after_create :associate_committers_with_self
  after_create :associate_tickets_with_self
  
  validates :project, :presence => true
  validates :sha, :presence => true
  validates :message, :presence => true
  validates :authored_at, :presence => true
  validates :committer, :presence => true
  validates :committer_email, :presence => true
  
  
  
  def self.during(range)
    where(authored_at: range)
  end
  
  def self.reachable
    where(unreachable: false)
  end
  
  
  
  def self.from_native_commit(native)
    new attributes_from_native_commit(native)
  end
  
  def self.attributes_from_native_commit(native)
    { :sha => native.sha,
      :message => native.message.strip,
      :authored_at => native.authored_at,
      :committer => native.author_name,
      :committer_email => native.author_email.downcase }
  end
  
  def native_commit
    project.repo.native_commit(sha)
  end
  
  
  
  def to_str
    sha
  end
  
  
  
  def skip?
    merge? || tags.member?("skip")
  end
  
  def merge?
    (message =~ MERGE_COMMIT_PATTERN).present?
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
  
  def hours_worked
    parsed_message[:hours_worked]
  end
  
  def extra_attributes
    parsed_message[:attributes]
  end
  
  
  
  def identify_committers
    proc = Houston.config.identify_committers_proc
    emails = proc ? Array(proc[self]) : [committer_email]
    User.where(email: emails.map(&:downcase)).to_a
  end
  
  
  
  def self.parse_message(message)
    tags = []
    tickets = []
    attributes = {}
    hours = 0
    clean_message = normalize_commit_message(message)
    
    clean_message.gsub!(TICKET_PATTERN) { tickets << $1; "" }
    clean_message.gsub!(TIME_PATTERN) { hours = $1.to_f; hours /= 60 if $2.starts_with?("m"); "" }
    clean_message.gsub!(EXTRA_ATTRIBUTE_PATTERN) { (attributes[$1] ||= []).push($2); "" }
    while clean_message.gsub!(TAG_PATTERN) { tags << $1; "" }; end
    
    {tags: tags, tickets: tickets, hours_worked: hours, attributes: attributes, clean_message: clean_message.strip}
  end
  
  def self.normalize_commit_message(message)
    message = message[/^.*(?=\n\n)/] || message # just take the first paragraph of the commit message
    message = message.gsub(/[\n\s]+/, ' ') # normalize white space within the message
  end
  
  
  
  TAG_PATTERN = /^\s*\[([^\]]+)\]\s*/
  
  TICKET_PATTERN = /\[#(\d+)\]/
  
  TIME_PATTERN = /\((\d*\.?\d+) ?(h|hrs?|hours?|m|min|minutes?)\)/
  
  EXTRA_ATTRIBUTE_PATTERN = /\{\{([^:\}]+):([^\}]+)\}\}/
  
  MERGE_COMMIT_PATTERN = /^Merge\b/
  
  
  
  def associate_tickets_with_self
    return if ticket_numbers.empty?
    
    project.find_or_create_tickets_by_number(ticket_numbers).each do |ticket|
      ticket.commits << self unless ticket.commits.exists?(id)
    end
  end
  
  
  
  def associate_committers_with_self
    self.committers = identify_committers
  end
  
  
  
private
  
  def parsed_message
    @parsed_message ||= self.class.parse_message(message)
  end
  
end
