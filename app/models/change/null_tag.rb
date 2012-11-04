class Change::NullTag
  
  def self.instance
    @instance ||= self.new
  end
  
  def id
    nil
  end
  
  def nil?
    true
  end
  
  def color
    "EFEFEF"
  end
  
  def name
    "&mdash;".html_safe
  end
  
  def to_partial_path
    "change/tags/null_tag"
  end
  
end
