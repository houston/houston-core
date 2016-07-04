class CacheKeyDependencies
  attr_reader :project

  def self.for(*projects)
    projects = projects[0] if projects.length == 1 && projects[0].respond_to?(:each)
    projects.each do |project|
      self.new(project).perform!
    end
  end

  def initialize(project)
    @project = ProjectDependencies.new(project)
  end

  def perform!
    KeyDependency.all.each do |dependency|
      version = ProjectDependency.new(project, dependency).version
      project.props["keyDependency.#{dependency.slug}"] = version.to_s
    end
    project.update_column :props, project.props.to_h
  end

end
