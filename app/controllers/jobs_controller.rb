class JobsController < ApplicationController

  def index
    authorize! :show, :jobs
    jobs_by_name = $scheduler.jobs.each_with_object({}) { |job, map|
      map[job.tags.first] = {
        name: job.tags.first,
        schedule: job.original } }

    jobs = Job.where(name: jobs_by_name.keys)

    most_recent_jobs = jobs.joins(<<-SQL)
    inner join (select name, max(started_at) "started_at" from jobs group by name) "most_recent"
    on jobs.name=most_recent.name and jobs.started_at=most_recent.started_at
    SQL
    most_recent_jobs.each do |job|
      jobs_by_name[job.name][:last] = job
    end

    jobs.group(:name).unscope(:order).pluck(:name, "COUNT(id)", "COUNT(CASE WHEN succeeded THEN 1 ELSE NULL END)", "AVG(EXTRACT(epoch from finished_at - started_at))").each do |name, runs, successful_runs, avg_duration|
      jobs_by_name[name].merge!(
        runs: runs,
        successful_runs: successful_runs,
        avg_duration: avg_duration )
    end

    @jobs = jobs_by_name.values
  end

  def show
    authorize! :show, :jobs
    @job_name = params[:slug]
    @jobs = Job.where(name: @job_name).preload(:error)
  end

  def run
    authorize! :run, :jobs
    Houston.actions.run params[:slug]
    redirect_to "/jobs", notice: "#{params[:slug]} is running"
  end

end
