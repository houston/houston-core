class ProjectDependency
  include ActionView::Helpers::TextHelper


  def initialize(*args)
    @project, @key_dependency, @version = args
    @version = project.dependency_version(key_dependency.slug) if args.length < 3
  end

  def self.for(project)
    project = ProjectDependencies.new(project)
    KeyDependency.all.map { |dependency| self.new(project, dependency) }.select(&:valid?)
  end



  attr_reader :project, :version, :key_dependency
  alias :dependency :key_dependency

  delegate :slug, :name, :versions, :latest_version, :target_versions, :to => :key_dependency

  def minor_version
    @minor_version ||= minor_version_of(version)
  end



  def valid?
    version && versions.any?
  end

  def nil?
    version.nil?
  end

  def up_to_date?
    @up_to_date ||= (version == target_versions.first)
  end



  def releases_since_version
    @releases_since_version ||= minor_versions.index(minor_version)
  end

  def minor_versions
    @minor_versions ||= versions.map(&method(:minor_version_of)).uniq
  end

  def patches
    @patches ||= begin
      stringified_versions = versions.map(&:to_s)
      current_minor_version = stringified_versions.first[/\d+\.\d+/]
      rx = /^#{current_minor_version}\.\d+$/
      stringified_versions.select { |version| version =~ rx }
    end
  end



  def maintenance_light
    return nil if nil?
    return maintenance_light_for_target_versions if target_versions.any?
    maintenance_light_for_latest_release
  end

  def maintenance_light_for_target_versions
    return MaintenanceLight.new(self, "green", "Nice! #{project.name} is running the latest version of #{dependency.name}.") if up_to_date?

    target_versions.each do |target_version|
      next unless minor_version_of(target_version) == minor_version

      patches_behind = patchlevel_of(target_version) - patchlevel_of(version)
      return MaintenanceLight.new(self, "spring-green", "#{project.name} is running a safe version of #{dependency.name}.") if patches_behind <= 0
      return MaintenanceLight.new(self, "yellow", "#{project.name} is running a version of #{dependency.name} only #{pluralize(patches_behind, "patch")} behind #{target_version}. It should be a painless upgrade.")
    end

    MaintenanceLight.new(self, "red", "#{project.name} is running an older version of #{dependency.name}. Watch for breaking changes!")
  end

  def maintenance_light_for_latest_release
    if releases_since_version > 2
      MaintenanceLight.new self, "red", "#{releases_since_version} versions out-of-date"
    elsif releases_since_version == 2
      MaintenanceLight.new self, "orange", "#{releases_since_version} versions out-of-date"
    elsif releases_since_version == 1
      MaintenanceLight.new self, "yellow", "1 version out-of-date"
    elsif version < latest_version
      MaintenanceLight.new self, "spring-green", "#{pluralize(patches.index(version.to_s), "patches")} out-of-date"
    else
      MaintenanceLight.new self, "green", "up-to-date"
    end
  end


private


  def minor_version_of(version)
    version.to_s[/\d+\.\d+/]
  end

  def patchlevel_of(version)
    version.to_s[/\d+$/].to_i
  end


end
