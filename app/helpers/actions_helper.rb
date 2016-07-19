module ActionsHelper

  def format_action_params(params)
    Houston::ParamsSerializer.new.dump params
  end

end
