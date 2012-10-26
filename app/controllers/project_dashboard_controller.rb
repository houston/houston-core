class ProjectDashboardController < ApplicationController
  
  def index
    @project = Project.find_by_slug!(params[:slug])
    @tickets = []
    @tickets = @project.ticket_system.find_tickets!("status-neq-closed") if @project.ticket_system
    
    @dependency_versions = {}
    Houston.config.key_dependencies.each do |dependency|
      
      @dependency_versions[dependency] = cache "rubygems/#{dependency}/#{Date.today.strftime('%Y%m%d')}/info" do
        
        versions = Rubygems::Gem.new(dependency).versions
        next unless versions.any?
        
        stringified_versions = versions.map(&:to_s)
        latest_version = versions.first
        current_minor_version = stringified_versions.first[/\d+\.\d+/]
        rx = /^#{current_minor_version}\.\d+$/
        patches = stringified_versions.select { |version| version =~ rx }
        
        {
          name: dependency.titleize,
          versions: versions,
          minor_versions: stringified_versions.map { |version| version[/\d+\.\d+/] }.uniq,
          patches: patches,
          latest: latest_version
        }
      end
    end
  end
  
end
