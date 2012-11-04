class Change < ActiveRecord::Base
  
  belongs_to :release
  
  delegate :project, :to => :release
  
  attr_accessor :_destroy
  
  validates :description, :length => 1...255
  
  
  def self.attributes_from_commit(commit)
    { description: commit.message[0..255] }
  end
  
  
  def tag
    Struct.new(:slug, :text).new("tag", "Tag")
  end
  
  
end
