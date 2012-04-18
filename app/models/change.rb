class Change < ActiveRecord::Base
  
  belongs_to :release
  
  attr_accessor :_destroy
  
end
