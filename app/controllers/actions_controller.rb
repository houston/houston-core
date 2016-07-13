class ActionsController < ApplicationController

  def index
    authorize! :show, :actions

    actions_by_name = Houston.actions.names.each_with_object({}) { |name, map| map[name] = { name: name } }
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
    authorize! :show, :actions
    @action_name = params[:slug]
    @actions = Action.where(name: @action_name).preload(:error)
  end

  def run
    authorize! :run, :actions
    Houston.actions.run params[:slug]
    redirect_to "/actions", notice: "#{params[:slug]} is running"
  end

end
