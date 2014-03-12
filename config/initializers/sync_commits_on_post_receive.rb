Houston.observer.on "hooks:post_receive" do |project, params|
  project.repo.refresh!(async: true)
end
