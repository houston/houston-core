class Change < ActiveRecord::Base
  
  belongs_to :release
  
  delegate :project, :to => :release
  
  attr_accessor :_destroy
  
end
