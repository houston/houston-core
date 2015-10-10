class Sprint < ActiveRecord::Base

  has_many :sprint_tasks
  has_many :tasks, through: :sprint_tasks, extend: UniqueAdd
  has_many :tickets, through: :tasks

  before_validation :set_default_end_date, on: :create

  def self.current
    find_by_date Date.today
  end

  def self.find_by_date(date)
    date = date.to_date if date.respond_to?(:to_date)
    find_by_end_date end_date_for(date)
  end

  def self.find_by_date!(date)
    date = date.to_date if date.respond_to?(:to_date)
    find_or_create_by(end_date: end_date_for(date))
  end

  def self.end_date_for(date)
    days_until_friday = 5 - date.wday
    days_until_friday += 7 if days_until_friday < 0
    date + days_until_friday
  end

  def previous
    Sprint.find_or_create_by(end_date: end_date - 7)
  end

  def next
    Sprint.find_or_create_by(end_date: end_date + 7)
  end

  def start_date
    end_date.beginning_of_week
  end

  def starts_at
    start_date.beginning_of_day
  end

  def ends_at
    end_date.end_of_day
  end

  def to_range
    starts_at..ends_at
  end

  def completed?
    Date.today > end_date
  end

  def lock!
    update_column :locked, true
  end

  def unlock!
    update_column :locked, false
  end

  def range
    starts_at..ends_at
  end

private

  def set_default_end_date
    self.end_date ||= self.class.end_date_for(Date.today)
  end

end
