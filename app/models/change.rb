class Change < ActiveRecord::Base
  
  belongs_to :release
  belongs_to :tag, :autosave => true
  
  delegate :project, :to => :release
  
  def _destroy
    marked_for_destruction?
  end
  
  def _destroy=(value)
    mark_for_destruction if ["1", true].member?(value)
  end
  
  validates :description, :length => 1...255
  validates :tag_id, :presence => true
  
  class << self
    def from_commit(commit)
      Change.new attributes_from_commit(commit)
    end
    
    def attributes_from_commit(commit)
      { description: commit.clean_message[0..255],
        tag: Tag.find_or_create_from_slug(commit.tags.first) }
    end
  end
  
  
  def tag
    super || Change::NullTag.instance
  end
  
  
end
