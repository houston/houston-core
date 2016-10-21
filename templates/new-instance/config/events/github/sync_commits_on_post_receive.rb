Houston.config.on "hooks:project:post_receive" => "github:commits:sync" do
  project.commits.sync!
end
