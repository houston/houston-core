class Environment < ActiveRecord::Base
  
  belongs_to :project
  has_many :releases, :dependent => :destroy
  
  def to_param
    slug
  end
  
end
