Houston.observer.on "hooks:post_receive" do |e|
  e.project.commits.sync!
end
