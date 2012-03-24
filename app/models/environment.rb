class Environment < ActiveRecord::Base
  
  belongs_to :project
  has_many :releases
  
  def to_param
    slug
  end
  
end
