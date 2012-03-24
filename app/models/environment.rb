class Environment < ActiveRecord::Base
  
  belongs_to :project
  
  def to_param
    slug
  end
  
end
