class Task < ActiveRecord::Base
  
  versioned initial_version: true, only: [:description, :effort]
  
  belongs_to :ticket
  belongs_to :sprint
  belongs_to :checked_out_by, class_name: "User"
  has_and_belongs_to_many :releases
  has_and_belongs_to_many :commits
  
  validates :ticket_id, :number, presence: true
  validate :description_must_be_present, :unless => :default_task?
  
  before_validation :assign_number, on: :create
  before_create :replace_the_tickets_default_task
  before_destroy :prevent_destroying_a_tickets_last_task
  
  attr_readonly :number
  
  default_scope { order(:number) }
  
  delegate :project, :to => :ticket
  
  
  
  class << self
    def open
      uncommitted.unreleased
    end
    
    def numbered(*numbers)
      where number: numbers.flatten
    end
    
    def lettered(*letters)
      numbered letters.flatten.map { |letter| to_number(letter) }
    end
    
    def default
      where description: nil
    end
    
    def uncommitted
      where first_commit_at: nil
    end
    
    def committed
      where(arel_table[:first_commit_at].not_eq(nil))
    end
    
    def unreleased
      where first_release_at: nil
    end
    
    def released
      where(arel_table[:first_release_at].not_eq(nil))
    end
    
    def in_current_sprint
      joins(:sprint).where("sprints.end_date >= current_date")
    end
    
    def checked_out_by(user)
      where(checked_out_by_id: user.id)
    end
  end
  
  
  
  def letter
    bytes = []
    remaining = number
    while remaining > 0
      bytes.unshift (remaining - 1) % 26 + 97
      remaining = (remaining - 1) / 26
    end
    bytes.pack "c*"
  end
  
  def description
    super || ticket.summary
  end
  
  def shorthand
    "#{ticket.number}#{letter}"
  end
  
  def checked_out?
    checked_out_at.present?
  end
  
  
  
  def release!(release)
    self.releases << release unless releases.exists?(release.id)
    cache_release_attributes release
  end
  
  def released?
    first_release_at.present?
  end
  
  
  
  def committed!(commit)
    self.commits << commit unless commits.exists?(commit.id)
    cache_commit_attributes commit
  end
  
  def committed?
    first_commit_at.present?
  end
  
  
  
  def completed?
    committed? || released?
  end
  
  
  
  def default_task?
    number == 1 && read_attribute(:description).nil?
  end
  
  
  
private
  
  def assign_number
    self.number = (Task.where(ticket_id: ticket_id).maximum(:number) || 0) + 1
  end
  
  def replace_the_tickets_default_task
    # the task we're creating might take this old task's number
    assign_number if ticket.tasks.open.default.delete_all > 0
    true # <-- this callback isn't preventing task from being saved
  end
  
  def description_must_be_present
    errors.add :description, "can't be blank" if read_attribute(:description).blank?
  end
  
  def prevent_destroying_a_tickets_last_task
    return false if ticket.tasks.pluck(:id) == [id]
  end
  
  def cache_release_attributes(release)
    update_attributes first_release_at: release.created_at unless released?
  end
  
  def cache_commit_attributes(commit)
    update_attributes first_commit_at: commit.authored_at unless committed?
  end
  
  def self.to_number(letter)
    letter.bytes.reverse.map_with_index { |byte, i| (byte - 96) * (26 ** i) }.sum
  end
  
end
