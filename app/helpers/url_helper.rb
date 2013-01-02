module UrlHelper
  
  
  
  def goldmine_case_number_url(number)
    "http://goldmineweb/DisplayCase.aspx?CaseNumber=#{number}"
  end
  
  def errbit_app_url(project)
    protocol = Houston.config.errbit[:port] == 443 ? "https" : "http"
    "#{protocol}://#{Houston.config.errbit[:host]}/apps/#{project.errbit_app_id}"
  end
  
  def errbit_err_url(project, err)
    "#{errbit_app_url(project)}/errs/#{err}"
  end
  
  
  
  # !nb: this is now very similar to code in `config/initializers/run_tests_on_post_receive.rb`
  
  def github_url?(project)
    project.version_control_location =~ /github/
  end
  
  def github_project_url(project)
    return "" unless github_url?(project)
    project.version_control_location.gsub(/^git@(?:www\.)?github.com:/, "https://github.com/").gsub(/^git:/, "https:").gsub(/\.git$/, "")
  end
  
  def github_commit_url(commit)
    "#{github_project_url(commit.project)}/commit/#{commit.sha}"
  end
  
  
  
  def new_relic_project_url(project)
    account_id = Houston.config.new_relic[:account_id]
    "https://rpm.newrelic.com/accounts/#{account_id}/applications/#{project.new_relic_id}"
  end
  
  
  
  def kanban_path(*args)
    main_app.root_path(*args)
  end
  
  def default_path_for(user)
    case user.role
    when "Tester"; user_path(user)
    else; root_path
    end
  end
  
  
  
  def releases_path(project, *args)
    options = args.extract_options!
    environment_name = args.first
    if environment_name
      "/projects/#{project.to_param}/environments/#{environment_name}/releases"
    else
      super(project, options)
    end
  end
  
  def release_path(release, options={})
    super(release.project.to_param, release.environment_name, release, options)
  end
  
  def edit_release_path(release, options={})
    super(release.project.to_param, release.environment_name, release, options)
  end
  
  
  
  def release_url(release, options={})
    super(release.project.to_param, release.environment_name, release, options)
  end
  
  def edit_release_url(release, options={})
    super(release.project.to_param, release.environment_name, release, options)
  end
  
  def new_release_url(release, options={})
    super(release.project.to_param, release.environment_name, options.merge(deploy_id: release.deploy_id))
  end
  
  
  
  def weekly_report_path(date=Date.today, options={})
    super(options.merge(year: date.year, month: date.month, day: date.day))
  end
  
  
  
  def image_url(image)
    "#{root_url}/images/#{image}"
  end
  
  
  
end
