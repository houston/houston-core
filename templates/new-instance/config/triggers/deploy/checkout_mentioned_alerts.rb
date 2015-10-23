Houston.config.on "alert:deployed" do |alert, deploy, commit|
  next if alert.checked_out_by
  next unless committer = commit.committers.first
  alert.update_attribute :checked_out_by, committer
end
