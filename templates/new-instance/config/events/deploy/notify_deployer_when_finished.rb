Houston.config do
  on "deploy:succeeded" => "deploy:slack-deployer-of-finished-deploy" do
    next if deploy.build_release.ignore?
    next unless deployer = deploy.user

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

  on "deploy:succeeded" => "deploy:email-deployer-of-finished-deploy" do
    next if deploy.build_release.ignore?

    maintainers = deploy.project.maintainers
    maintainers.each do |maintainer|
      Houston.deliver! Houston::Releases::Mailer.maintainer_of_deploy(maintainer, deploy)
    end

    deployer = deploy.deployer
    if !deployer.blank? && !maintainers.with_email_address(deployer).exists?
      Houston.deliver! Houston::Releases::Mailer.maintainer_of_deploy(deployer, deploy)
    end
  end
end
