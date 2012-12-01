class KeyDependency
  
  
  def initialize(dependency)
    @slug = dependency
    @name = dependency.titleize
    
    @versions = KeyDependency.versions_for(dependency)
    @latest_version = versions.first
    
    if versions.any?
      stringified_versions = versions.map(&:to_s)
      current_minor_version = stringified_versions.first[/\d+\.\d+/]
      rx = /^#{current_minor_version}\.\d+$/
      @patches = stringified_versions.select { |version| version =~ rx }
      @minor_versions = stringified_versions.map { |version| version[/\d+\.\d+/] }.uniq
    else
      @patches = []
      @minor_versions = []
    end
  end
  
  
  attr_reader :slug, :name, :versions, :latest_version, :minor_versions, :patches
  
  
  def self.all
    @dependency_versions ||= Houston.config.key_dependencies.map do |dependency|
      KeyDependency.new(dependency)
    end
  end
  
  
  def self.versions_for(dependency)
    
    # Right now the only supported dependencies are Ruby Gems
    # In the future, as other kinds of dependencies are supported,
    # we'll support different adapters to fetch their version info
    Rubygems::Gem.new(dependency).versions
  end
  
  
end
