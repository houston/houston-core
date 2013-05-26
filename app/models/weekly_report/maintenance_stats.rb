class WeeklyReport
  class MaintenanceStats
    
    def initialize(projects: Project.scoped)
      @projects = projects
    end
    
    attr_reader :projects
    
    def each
      projects.each do |project|
        ProjectDependency.for(project).each do |dependency|
          next if dependency.up_to_date?
          indicator = dependency.maintenance_light
          
          yield project, dependency, indicator
        end
      end
    end
    
  end
end
