class Project < ActiveRecord::Base
  
  has_many :environments
  
  def name
    title
  end
  
  def to_param
    slug
  end
  
end
