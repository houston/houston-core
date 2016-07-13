Houston.config.on "alert:deployed" => "alert:assign-alert-to-committer" do
  next if alert.checked_out_by
  next unless committer = commit.committers.first
  alert.update_attribute :checked_out_by, committer
end
