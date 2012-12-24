class Environment < ActiveRecord::Base
  
  belongs_to :project
  has_many :releases, :dependent => :destroy
  has_many :deploys, :dependent => :destroy
  
  validates :slug, :name, :presence => true
  
  before_validation :set_default_name
  
  def to_param
    slug
  end
  
  def last_commit
    last_release = releases.first
    last_release ? last_release.commit1 : initial_commit
  end
  
private
  
  def set_default_name
    self.name ||= slug.titleize
  end
  
end
