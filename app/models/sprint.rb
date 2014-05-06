class Sprint < ActiveRecord::Base
  
  has_many :tickets
  
  before_validation :set_default_end_date, on: :create
  
  def self.current
    where("end_date >= current_date").order("end_date DESC").first
  end
  
  def lock!
    update_column :locked, true
  end
  
  def unlock!
    update_column :locked, false
  end
  
private
  
  def set_default_end_date
    self.end_date ||= begin
      today = Date.today
      days_until_friday = 5 - today.wday
      days_until_friday += 7 if days_until_friday < 0
      today + days_until_friday
    end
  end
  
end
