Houston.observer.on "hooks:project:post_receive" do |e|
  e.project.commits.sync!
end
