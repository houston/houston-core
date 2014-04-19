Houston.observer.on "hooks:post_receive" do |project, params|
  project.repo.refresh!
  
  payload = PostReceivePayload.new(params)
  if payload.branch == project.gemnasium_branch && !project.gemnasium_slug.blank?
    PushGemfileToGemnasium.new(project).perform
  end
end
