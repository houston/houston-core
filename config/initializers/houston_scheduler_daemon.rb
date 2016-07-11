require "rufus/scheduler"

Houston.daemonize "scheduler" do
  $scheduler = Rufus::Scheduler.new
  $scheduler.join
end
