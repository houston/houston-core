class Dependency
  
  def initialize(name, version)
    @name, @version = name, version
  end
  
  attr_reader :name, :version
  
  def to_s
    "#{name} #{version}"
  end
  
  def blank?
    false
  end
  
end
