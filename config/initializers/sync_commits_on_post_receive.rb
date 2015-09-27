Houston.observer.on "hooks:post_receive" do |project, params|
  project.commits.sync!
end
