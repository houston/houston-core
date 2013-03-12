class Error < ActiveRecord::Base
  
  belongs_to :project
  
  validates_presence_of :message
  validates_inclusion_of :category, :in => %w{unfuddle configuration}
  
  serialize :backtrace
  
  after_create { Houston.observer.fire "error:create", self }
  
end
