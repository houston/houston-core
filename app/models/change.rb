class Change < ActiveRecord::Base
  
  belongs_to :release
  
  delegate :project, :to => :release
  
  validates :description, :length => 1...255
  
  class << self
    
    def from_commit(commit)
      Change.new attributes_from_commit(commit)
    end
    
    def attributes_from_commit(commit)
      { description: commit.clean_message[0..255],
        tag: Houston.config.fetch_tag(commit.tags.first) }
    end
    
  end
  
  
  
  def tag
    Houston.config.fetch_tag(tag_slug)
  end
  
  def tag=(value)
    self.tag_slug = value.slug
  end
  
  
  
  def _destroy
    marked_for_destruction?
  end
  
  def _destroy=(value)
    mark_for_destruction if ["1", true].member?(value)
  end
  
  
  
end
