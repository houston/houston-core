class Environment < ActiveRecord::Base
  
  belongs_to :project
  has_many :releases, :dependent => :destroy
  
  def to_param
    slug
  end
  
  def last_commit
    last_release = releases.first
    last_release ? last_release.commit1 : initial_commit
  end
  
end
