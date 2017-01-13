class Task < ActiveRecord::Base

  versioned initial_version: true, only: [:description, :effort]

  belongs_to :ticket
  belongs_to :project
  has_and_belongs_to_many :commits

  validates :project_id, :ticket_id, :number, presence: true
  validate :description_must_be_present, :unless => :default_task?

  before_validation :set_project_id, on: :create
  before_validation :assign_number, on: :create
  before_destroy :prevent_destroying_a_tickets_last_task

  attr_readonly :number

  default_scope { order(:number).joins(:ticket) }



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

    def completed
      where(arel_table[:completed_at].not_eq(nil))
    end

    def find_by_project_and_shorthand(project_slug, shorthand)
      with_shorthand(shorthand)
        .merge(Ticket.joins(:project)
          .where(Project.arel_table[:slug].eq(project_slug)))
        .first
    end

    def with_shorthand(shorthand)
      _, ticket_number, letter = shorthand.split /(\d+)([a-z]+)/
      joins(:ticket)
        .where(Ticket.arel_table[:number].eq(ticket_number))
        .lettered(letter)
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



  def mark_committed!(commit)
    update_column :first_commit_at, commit.authored_at unless committed?
    Houston.observer.fire "task:committed", task: self
  end

  def committed?
    first_commit_at.present?
  end



  def completed!
    return if completed?
    touch :completed_at
    Houston.observer.fire "task:completed", task: self
  end
  alias :complete! :completed!

  def completed?
    completed_at.present?
  end

  def manually_completed?
    completed? && !committed?
  end



  def reopen!
    return unless manually_completed?
    update_column :completed_at, nil
    Houston.observer.fire "task:reopened", task: self
  end

  def open?
    !completed?
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
    throw :abort if ticket.tasks.pluck(:id) == [id]
  end

  def self.to_number(letter)
    letter.bytes.reverse.each_with_index.map { |byte, i| (byte - 96) * (26 ** i) }.sum
  end

end
