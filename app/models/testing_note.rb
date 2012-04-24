class TestingNote < ActiveRecord::Base
  
  belongs_to :user
  belongs_to :ticket
  
  VERDICTS = %w{works fails}
  
  validate :verdict, :presence => true, :inclusion => VERDICTS
  
end
