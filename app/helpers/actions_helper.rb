module ActionsHelper

  def format_action_params(params)
    MultiJson.dump params
  end

end
