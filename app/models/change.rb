class Change < ActiveRecord::Base
  
  belongs_to :release
  
  delegate :project, :to => :release
  
  attr_accessor :_destroy
  
  validates_length_of :description, :maximum => 255
  
end
