Houston.observer.on "deploy:create" do |deploy|
  deploy.project.maintainers.each do |maintainer|
    ProjectMailer.notify_maintainer_of_deploy(maintainer, deploy).deliver!
  end
end
