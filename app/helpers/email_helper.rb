module EmailHelper

  def render_scss(relative_path)
    asset = sprockets_env.find_asset(relative_path)
    raise "Asset not found #{relative_path.inspect}" unless asset
    asset.to_s.html_safe
  end

  def for_email?
    @for_email == true
  end

  def sprockets_env
    # In environments where assets.compile = false, Sprockets will no longer
    # instantiate the Sprockets environment at Rails.application.assets.
    #
    # See how different gems worked around this change:
    #    https://github.com/Compass/compass-rails/issues/257#issuecomment-174819398
    #    https://github.com/wwidea/font-awesome-rails/pull/2
    #    https://github.com/rails/sprockets-rails/issues/311#issuecomment-172395232
    #
    # The last seems to be the recommended solution; but not all assets show up
    # in the manifest; and it will still give an error ("manifest requires
    # environment for compilation"). Therefore, we'll create the compilation
    # environment for the sake of the mailer.
    return Rails.application.assets if Rails.application.assets
    return @sprockets_env if defined?(@sprockets_env)
    @sprockets_env = Sprockets::Railtie.build_environment(Rails.application)
  end

end
