Houston.config do
  on "deploy:completed" do |deploy|
    next if deploy.build_release.ignore?

    deployer = deploy.user
    if deployer
      message = "#{deployer.first_name}, your deploy of #{deploy.project.slug} " <<
                "to #{deploy.environment_name} just finished. " <<
                slack_link_to("Click here to write release notes",
                  Rails.application.routes.url_helpers.new_release_url(
                    deploy.project.to_param,
                    deploy.environment_name,
                    host: Houston.config.host,
                    deploy_id: deploy.id,
                    auth_token: deployer.authentication_token))
      slack_send_message_to message, deployer
    end

    Houston.try({max_tries: 3}, Net::OpenTimeout) do
      DeployNotification.new(deploy).deliver! # <-- after extracting releases, move this to Releases
    end
  end
end
