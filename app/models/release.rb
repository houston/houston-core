class Release < ActiveRecord::Base
  
  belongs_to :environment
  has_many :changes
  
  default_scope order("created_at DESC")
  
  delegate :project, :to => :environment
  
  default_value_for :name do
    Time.now.strftime("%A, %b %e, %Y %H:%M:%S")
  end
  
end
