class ReleaseChange
  include ActiveModel::Validations  
  
  validates :description, :length => 1...255
  # validates :tag_slug, :in => 
  
  ENCODING_PATTERN = /^\[([^\]]*)\] (.*)$/.freeze
  
  def initialize(release, tag_slug, description)
    @release = release
    @tag_slug = tag_slug
    @description = description[/^.*$/]
  end
  
  attr_reader :release, :tag_slug, :description
  
  class << self
    
    def from_s(release, string)
      new release, *(string.match(ENCODING_PATTERN)[1..2])
    end
    
    def from_commit(release, commit)
      message = commit.clean_message[0..255]
      message[0] = message[0].upcase if message[0]
      new release, commit.tags.first, message
    end
    
  end
  
  def to_s
    "[#{tag_slug}] #{description}"
  end
  
  def tag
    Houston.config.fetch_tag(tag_slug)
  end
  
  
  
  def id
    hash
  end
  
  def marked_for_destruction?
    false
  end
  
  def _destroy
    marked_for_destruction?
  end
  
end
