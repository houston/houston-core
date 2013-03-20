class KeyDependency
  
  
  def initialize(attributes={})
    @slug = attributes[:slug]
    @name = attributes.fetch(:as, @slug.titleize)
    @target_versions = attributes.fetch(:target_versions, []).map(&Gem::Version.method(:new))
  end
  
  
  
  attr_reader :slug, :name, :target_versions
  
  def versions
    @versions ||= KeyDependency.versions_for(self)
  end
  
  def latest_version
    versions.first
  end
  
  def to_s
    slug
  end
  
  
  
  def self.all
    @dependency_versions ||= Houston.config.key_dependencies.map do |dependency|
      KeyDependency.new(dependency)
    end
  end
  
  
  
  def self.versions_for(dependency)
    
    # Right now the only supported dependencies are Ruby Gems
    # In the future, as other kinds of dependencies are supported,
    # we'll support different adapters to fetch their version info
    Rubygems::Gem.new(dependency.slug).versions
  end
  
  
end
