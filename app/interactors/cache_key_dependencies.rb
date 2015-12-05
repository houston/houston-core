class CacheKeyDependencies
  attr_reader :project

  def self.for(*projects)
    projects = projects[0] if projects.length == 1 && projects[0].respond_to?(:each)
    projects.each do |project|
      begin
        self.new(project).perform!
      rescue StandardError => e
        Houston.report_exception(e)
      end
    end
  end

  def initialize(project)
    @project = ProjectDependencies.new(project)
  end

  def perform!
    KeyDependency.all.each do |dependency|
      version = ProjectDependency.new(project, dependency).version
      project.extended_attributes = project.extended_attributes.merge(
        "key_dependency.#{dependency.slug}" => version)
    end
    project.update_column :extended_attributes, project.extended_attributes
  end

end
