class Task < ActiveRecord::Base
  
  versioned initial_version: true, only: [:description, :effort]
  
  belongs_to :ticket
  belongs_to :project
  has_and_belongs_to_many :sprints, extend: UniqueAdd
  has_and_belongs_to_many :releases
  has_and_belongs_to_many :commits
  
  validates :project_id, :ticket_id, :number, presence: true
  validate :description_must_be_present, :unless => :default_task?
  
  before_validation :set_project_id, on: :create
  before_validation :assign_number, on: :create
  before_destroy :prevent_destroying_a_tickets_last_task
  
  attr_readonly :number
  
  default_scope { order(:number) }
  
  
  
  class << self
    def open
      where completed_at: nil
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
    
    def completed
      where(arel_table[:completed_at].not_eq(nil))
    end
    
    def completed_during(sprint)
      where(arel_table[:completed_at].in(sprint.range).or(arel_table[:first_commit_at].in(sprint.range)))
    end
    
    def in_current_sprint
      joins(:sprint).where("sprints.end_date >= current_date")
    end
    
    def checked_out_by(user)
      where(checked_out_by_id: user.id)
    end
    
    def find_by_project_and_shorthand(project_slug, shorthand)
      _, ticket_number, letter = shorthand.split /(\d+)([a-z]+)/
      where(ticket_id: Ticket.joins(:project)
          .where(Project.arel_table[:slug].eq(project_slug))
          .where(Ticket.arel_table[:number].eq(ticket_number)))
        .lettered(letter).first
    end
    
    def versions
      VestalVersions::Version.where(versioned_type: "Task", versioned_id: pluck(:id))
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
  
  
  
  def released!(release)
    self.releases << release unless releases.exists?(release.id)
    update_column :first_release_at, release.created_at unless released?
    Houston.observer.fire "task:released", self
  end
  
  def released?
    first_release_at.present?
  end
  
  
  
  def committed!(commit)
    update_column :first_commit_at, commit.authored_at unless committed?
    Houston.observer.fire "task:committed", self
  end
  
  def committed?
    first_commit_at.present?
  end
  
  
  
  def completed!
    return if completed?
    touch :completed_at
    Houston.observer.fire "task:completed", self
  end
  alias :complete! :completed!
  
  def completed?
    completed_at.present?
  end
  
  def manually_completed?
    completed? && !committed? && !released?
  end
  
  
  
  def reopen!
    return unless manually_completed?
    update_column :completed_at, nil
    Houston.observer.fire "task:reopened", self
  end
  
  def open?
    !completed?
  end
  
  
  
  def checked_out?(sprint)
    SprintTask.where(sprint_id: sprint.id, task_id: id).checked_out.exists?
  end
  
  def checked_out_by_me?(sprint, user)
    SprintTask.where(sprint_id: sprint.id, task_id: id).checked_out_by(user).exists?
  end
  
  def check_out!(sprint, user)
    SprintTask.where(sprint_id: sprint.id, task_id: id).check_out!(user)
  end
  
  def check_in!(sprint)
    SprintTask.where(sprint_id: sprint.id, task_id: id).check_in!
  end
  
  
  
  def default_task?
    number == 1 && read_attribute(:description).nil?
  end
  
  
  
private
  
  def set_project_id
    self.project_id = ticket.project_id if ticket
  end
  
  def assign_number
    self.number = (Task.where(ticket_id: ticket_id).maximum(:number) || 0) + 1
  end
  
  def description_must_be_present
    errors.add :description, "can't be blank" if read_attribute(:description).blank?
  end
  
  def prevent_destroying_a_tickets_last_task
    return false if ticket.tasks.pluck(:id) == [id]
  end
  
  def self.to_number(letter)
    letter.bytes.reverse.map_with_index { |byte, i| (byte - 96) * (26 ** i) }.sum
  end
  
end
