class ActionsController < ApplicationController

  def index
    authorize! :read, Action

    actions_by_name = Houston.actions.to_a.each_with_object({}) { |action, map|
      map[action.name] = { name: action.name, required_params: action.required_params } }
    actions = Action.where(name: actions_by_name.keys)

    most_recent_actions = actions.joins(<<-SQL)
    inner join (select name, max(started_at) "started_at" from actions group by name) "most_recent"
    on actions.name=most_recent.name and actions.started_at=most_recent.started_at
    SQL
    most_recent_actions.each do |action|
      actions_by_name[action.name][:last] = action
    end

    actions.group(:name).unscope(:order).pluck(:name, "COUNT(id)", "COUNT(CASE WHEN succeeded THEN 1 ELSE NULL END)", "AVG(EXTRACT(epoch from finished_at - started_at))").each do |name, runs, successful_runs, avg_duration|
      actions_by_name[name].merge!(
        runs: runs,
        successful_runs: successful_runs,
        avg_duration: avg_duration )
    end

    @actions = actions_by_name.values
  end

  def show
    authorize! :read, Action
    @action_name = params[:slug]
    @actions = Action.where(name: @action_name).preload(:error).limit(50)
    @actions = @actions.where(Action.arel_table[:created_at].lt(params[:before])) if params[:before]
    render partial: "actions/actions" if request.xhr?
  end

  def running
    authorize! :read, Action
    @actions = Action.running
  end

  def run
    authorize! :run, Action
    Houston.actions.run params[:slug]
    redirect_to "/actions", notice: "#{params[:slug]} is running"
  end

  def retry
    authorize! :run, Action
    action = Action.find(params[:id])
    action.retry!
    redirect_to :back
  end

end
