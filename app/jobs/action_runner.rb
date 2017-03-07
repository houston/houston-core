class ActionRunner < ApplicationJob
  queue_as :default

  def perform(action)
    exception = nil

    Houston.reconnect do
      action.touch :started_at
      Houston.actions.fetch(action.name).execute(action.params)
    end

  rescue *::Action.ignored_exceptions

    # Note that the action failed, but do not report _these_ exceptions
    exception = $!

  rescue Exception # rescues StandardError by default; but we want to rescue and report all errors

    # Report all other exceptions
    exception = $!
    Houston.report_exception($!, parameters: {
      action_id: action.id,
      action_name: action.name,
      trigger: action.trigger,
      params: action.params
    })

  ensure
    begin
      Houston.reconnect do
        action.finish! exception
      end
    rescue Exception # rescues StandardError by default; but we want to rescue and report all errors
      Houston.report_exception($!, parameters: {
        action_id: action.id,
        action_name: action.name,
        trigger: action.trigger,
        params: action.params
      })
    end
  end

end
