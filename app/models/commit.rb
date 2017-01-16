class Commit < ActiveRecord::Base

  belongs_to :project
  belongs_to :parent, foreign_key: :parent_sha, primary_key: :sha, class_name: "Commit"
  has_many :children, foreign_key: :parent_sha, primary_key: :sha, class_name: "Commit"
  has_and_belongs_to_many :committers, class_name: "User"
  has_and_belongs_to_many :pull_requests, class_name: "Github::PullRequest"

  default_scope { order(:created_at) }

  after_create :associate_committers_with_self
  after_create { Houston.observer.fire "commit:create", commit: self }

  validates :project, presence: true
  validates :sha, presence: true, uniqueness: true
  validates :message, presence: true
  validates :authored_at, presence: true
  validates :committer, presence: true
  validates :committer_email, presence: true



  class << self
    def find_by_sha(sha)
      with_sha_like(sha).first if sha
    end

    def with_sha_like(sha)
      where(["sha LIKE ?", "#{sha.strip}%"])
    end

    def during(range)
      where(authored_at: range)
    end

    def reachable
      where(unreachable: false)
    end

    def unreachable
      where(unreachable: true)
    end

    def latest
      last
    end

    def earliest
      first
    end
  end



  def summary
    message[/^.*$/]
  end

  def description
    message.lines[1..-1].join("\n")
  end



  def self.from_native_commit(native)
    new attributes_from_native_commit(native)
  end

  def self.attributes_from_native_commit(native)
    { :sha => native.sha,
      :parent_sha => native.parent_sha,
      :message => native.message.to_s.strip,
      :authored_at => native.authored_at,
      :committer => native.author_name,
      :committer_email => native.author_email.to_s.downcase }
  end

  def native_commit
    project.repo.native_commit(sha)
  end



  def to_str
    sha
  end

  def to_s
    sha
  end

  def url
    @url ||= begin
      repo = project.repo if project
      repo.commit_url(sha) if repo.respond_to?(:commit_url)
    end
  end



  def skip?
    merge? || tags.member?("skip")
  end

  def merge?
    (message =~ MERGE_COMMIT_PATTERN).present?
  end



  def ticket_numbers
    parsed_message[:tickets]
  end

  def tags
    parsed_message[:tags]
  end

  def clean_message
    parsed_message[:clean_message]
  end

  def hours_worked
    parsed_message[:hours_worked]
  end

  def extra_attributes
    parsed_message[:attributes]
  end



  def committer_hours
    (hours_worked || 0) * committers.count
  end



  def identify_committers
    emails = Houston.config.identify_committers(self)
    User.with_email_address(emails).to_a
  end



  def associate_committers_with_self
    self.committers = identify_committers
  end



  TAG_PATTERN = /^\s*\[([^\]]+)\]\s*/.freeze
  TICKET_PATTERN = /\[#(\d+)\]/.freeze
  TIME_PATTERN = /\((\d*\.?\d+) ?(h|hrs?|hours?|m|min|minutes?)\)/.freeze
  EXTRA_ATTRIBUTE_PATTERN = /\{\{([^:\}]+):[ \s]*([^\}]+)\}\}/.freeze
  MERGE_COMMIT_PATTERN = /^Merge\b/.freeze

protected

  def parsed_message
    @parsed_message ||= parse_message(normalize_commit_message(message))
  end

  def parse_message(clean_message)
    tickets = []
    tags = []
    attributes = {}
    hours = 0

    clean_message.gsub!(TICKET_PATTERN) { tickets << $1.to_i; "" }
    clean_message.gsub!(TIME_PATTERN) { hours = $1.to_f; hours /= 60 if $2.starts_with?("m"); "" }
    clean_message.gsub!(EXTRA_ATTRIBUTE_PATTERN) { (attributes[$1] ||= []).concat($2.split(",").map(&:strip).reject(&:blank?)); "" }
    while clean_message.gsub!(TAG_PATTERN) { tags << $1; "" }; end

    {tags: tags, tickets: tickets, hours_worked: hours, attributes: attributes, clean_message: clean_message.strip}
  end

  def normalize_commit_message(message)
    message = message[/^.*(?=\n\n)/] || message # just take the first paragraph of the commit message
    message = message.gsub(/[\n\s]+/, ' ') # normalize white space within the message
  end

end
