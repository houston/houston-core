class MaintenanceLight
  
  
  def initialize(project, key_dependency)
    @project = project
    @key_dependency = key_dependency
    
    project_version = project.dependency_version(key_dependency.slug)
    @version = project_version && project_version.version
  end
  
  
  def self.for(project)
    KeyDependency.all.map { |dependency| self.new(project, dependency) }.select(&:valid?)
  end
  
  
  attr_reader :version, :key_dependency
  
  delegate :slug, :name, :latest_version, :to => :key_dependency
  
  
  def valid?
    version && key_dependency.versions.any?
  end
  
  
  def update_to_date?
    color == "green"
  end
  
  
  def releases_since_version
    @releases_since_version ||= begin
      minor_version = version.to_s[/\d+\.\d+/]
      key_dependency.minor_versions.index(minor_version)
    end
  end
  
  
  def color
    if releases_since_version > 2
      "red"
    elsif releases_since_version == 2
      "orange"
    elsif releases_since_version == 1
      "yellow"
    elsif version < key_dependency.latest_version
      "spring-green"
    else
      "green"
    end
  end
  
  
  def message
    if releases_since_version > 1
      "#{releases_since_version} versions out-of-date"
    elsif releases_since_version == 1
      "1 version out-of-date"
    elsif version < key_dependency.latest_version
      patches_since_version = key_dependency.patches.index(version.to_s)
      "#{pluralize(patches_since_version, "patches")} out-of-date"
    else
      "up-to-date"
    end
  end
  
  
end
