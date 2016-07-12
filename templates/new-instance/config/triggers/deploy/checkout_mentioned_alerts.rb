Houston.config.on "alert:deployed" do |e|
  next if e.alert.checked_out_by
  next unless committer = e.commit.committers.first
  e.alert.update_attribute :checked_out_by, committer
end
