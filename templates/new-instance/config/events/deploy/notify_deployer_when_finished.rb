Houston.config do
  on "deploy:completed" do |e|
    next if e.deploy.build_release.ignore?

    deployer = e.deploy.user
    if deployer
      message = "#{deployer.first_name}, your deploy of #{e.deploy.project.slug} " <<
                "to #{e.deploy.environment_name} just finished. " <<
                slack_link_to("Click here to write release notes",
                  Rails.application.routes.url_helpers.new_release_url(
                    e.deploy.project.to_param,
                    e.deploy.environment_name,
                    host: Houston.config.host,
                    deploy_id: e.deploy.id,
                    auth_token: deployer.authentication_token))
      slack_send_message_to message, deployer
    end

    Houston.try({max_tries: 3}, Net::OpenTimeout) do
      DeployNotification.new(e.deploy).deliver! # <-- after extracting releases, move this to Releases
    end
  end
end
