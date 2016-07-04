class ConvertMinPassingVerdictsToProps < ActiveRecord::Migration
  def up
    require "progressbar"
    projects = Project.all
    pbar = ProgressBar.new("projects", projects.count)
    projects.find_each do |project|
      min_passing_verdicts = project.read_attribute(:min_passing_verdicts)
      project.update_prop! "testingReport.minPassingVerdicts", min_passing_verdicts.to_s
      pbar.inc
    end
    pbar.finish
  end
end
