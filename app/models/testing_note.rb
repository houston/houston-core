class TestingNote < ActiveRecord::Base
  
  belongs_to :user
  belongs_to :ticket
  
  VERDICTS = %w{works fails}
  
  validates :user, :presence => true
  validates :ticket, :presence => true
  validates :comment, :presence => true, :length => 1..250
  validates :verdict, :presence => true, :inclusion => VERDICTS
  
end
