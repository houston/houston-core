class ProjectDependenciesController < ApplicationController
  
  def index
    @target_versions = Houston.config.key_dependencies.each_with_object({}) do |options, hash|
      hash[KeyDependency.new(options)] = options[:target_versions]
    end
    
    @environments = Houston.config.environments
    
    @project_dependencies = []
    projects = Project.scoped
    projects = Project.where(slug: "360") if Rails.env.development?
    projects.each do |project|
      dependency_versions = []
      
      @target_versions.keys.each do |dependency|
        versions = @environments.map do |environment_name|
          version = project.environment(environment_name).dependency_version(dependency)
          ProjectDependency.new(project, dependency, version)
        end
        
        dependency_versions << [dependency].concat(versions) unless versions.all?(&:nil?)
      end
      
      @project_dependencies << [project].concat(dependency_versions) unless dependency_versions.empty?
    end
  end
  
end
