module ExposureHelper

  def alpha
    yield if Rails.env.development?
  end

  def beta
    yield if current_user && current_user.owner?
  end

end
