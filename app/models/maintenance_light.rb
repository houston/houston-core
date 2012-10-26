class MaintenanceLight
  
  
  def self.for(project)
    [].tap do |maintenance_lights|
      KeyDependency.versions.each do |dependency, version_info|
        project_version = project.dependency_version(dependency)
        next unless project_version
        maintenance_lights << self.new(project_version.version, version_info)
      end
    end
  end
  
  
  attr_reader :version
  
  
  def releases_since_version
    @releases_since_version ||= begin
      minor_version = version.to_s[/\d+\.\d+/]
      version_info[:minor_versions].index(minor_version)
    end
  end
  
  
  def name
    version_info[:name]
  end
  
  
  def color
    if releases_since_version > 2
      "red"
    elsif releases_since_version == 2
      "orange"
    elsif releases_since_version == 1
      "yellow"
    elsif version < version_info[:latest]
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
    elsif version < version_info[:latest]
      patches_since_version = version_info[:patches].index(version.to_s)
      "#{pluralize(patches_since_version, "patches")} out-of-date"
    else
      "up-to-date"
    end
  end
  
  
private
  
  
  def initialize(version, version_info)
    @version = version
    @version_info = version_info
  end
  
  
  attr_reader :version_info
  
  
end
