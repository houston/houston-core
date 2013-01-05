Houston.observer.on "deploy:create" do |deploy|
  deploy.project.maintainers.each do |maintainer|
    ProjectNotification.maintainer_of_deploy(maintainer, deploy).deliver!
  end
end
