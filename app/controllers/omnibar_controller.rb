class OmnibarController < ApplicationController

  def show
    results = []
    query = params[:query]
    filter = [:commit, :ticket, :project]
    query, filter = query[1..-1], [:ticket] if query.starts_with? "#"
    query, filter = query[1..-1], [:commit] if query.starts_with? "@"

    Commit.includes(:project).where(["sha like ?", "#{query}%"]).each do |commit|
      results << {
        type: "commit",
        projectTitle: commit.project.name,
        projectColor: commit.project.color,
        url: "/commits/#{commit.sha}",
        sha: commit.sha,
        message: commit.message,
        committer: {
          name: commit.committer,
          email: commit.committer_email } }
    end if filter.member? :commit

    Ticket.includes(:project, :reporter).where(["number::text like ?", "#{query}%"]).each do |ticket|
      next unless ticket.project
      results << {
        type: "ticket",
        projectTitle: ticket.project.name,
        projectColor: ticket.project.color,
        url: "/projects/#{ticket.project.slug}/tickets/by_number/#{ticket.number}",
        number: ticket.number,
        summary: ticket.summary,
        reporter: ticket.reporter && {
          name: ticket.reporter.name,
          email: ticket.reporter.email } }
    end if filter.member? :ticket

    Project.where(["slug like ?", "#{query}%"]).each do |project|
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
    end if filter.member? :project

    render json: results
  end

end
