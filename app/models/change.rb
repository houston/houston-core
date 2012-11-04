class Change < ActiveRecord::Base
  
  belongs_to :release
  
  delegate :project, :to => :release
  
  validates :description, :length => 1...255
  def _destroy
    marked_for_destruction?
  end
  
  def _destroy=(value)
    mark_for_destruction if ["1", true].member?(value)
  end
  
  def self.attributes_from_commit(commit)
    { description: commit.clean_message[0..255] }
  end
  
  
  def tag
    Struct.new(:slug, :text).new("tag", "Tag")
  end
  
  
end
