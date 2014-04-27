class OmnibarController < ApplicationController
  
  def show
    results = []
    
    Commit.includes(:project).where(["sha like ?", "#{params[:query]}%"]).each do |commit|
      results << { type: "commit",
        projectTitle: commit.project.name,
        projectColor: commit.project.color,
        url: "/commits/#{commit.sha}",
        sha: commit.sha,
        message: commit.message,
        committer: {
          name: commit.committer,
          email: commit.committer_email } }
    end
    
    Project.where(["slug like ?", "#{params[:query]}%"]).each do |project|
      results.concat [{
        type: "project",
        projectTitle: project.name,
        projectColor: project.color,
        title: "Scheduler",
        url: "/scheduler/by_project/#{project.slug}" },
      { type: "project",
        projectTitle: project.name,
        projectColor: project.color,
        title: "Testing Report",
        url: "/testing_report/#{project.slug}" },
      { type: "project",
        projectTitle: project.name,
        projectColor: project.color,
        title: "Releases",
        url: "/projects/#{project.slug}/releases" },
      { type: "project",
        projectTitle: project.name,
        projectColor: project.color,
        title: "Pretickets",
        url: "/pretickets/by_project/#{project.slug}" }]
    end
    
    render json: results
  end
  
end
