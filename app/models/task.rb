class Task < ActiveRecord::Base
  
  belongs_to :ticket
  belongs_to :sprint
  belongs_to :checked_out_by, class_name: "User"
  has_and_belongs_to_many :releases
  has_and_belongs_to_many :commits
  
  validates :ticket_id, :number, :description, presence: true
  
  before_validation :assign_number, on: :create
  before_destroy :prevent_destroying_a_tickets_last_task
  
  attr_readonly :number
  
  delegate :project, :to => :ticket
  
  
  
  class << self
    def open
      where first_release_at: nil
    end
    
    def numbered(*numbers)
      where number: numbers.flatten
    end
    
    def lettered(*letters)
      numbered letters.flatten.map { |letter| to_number(letter) }
    end
    
    def committed
      where(arel_table[:first_commit_at].not_eq(nil))
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
  
  
  
private
  
  def assign_number
    self.number = (Task.where(ticket_id: ticket_id).maximum(:number) || 0) + 1
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
