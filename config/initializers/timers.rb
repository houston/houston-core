scheduler = Rufus::Scheduler.singleton

Houston.config.timers.each do |(interval, block)|
  scheduler.every(interval) do |job|
    Rails.logger.debug "\e[94m[interval:#{interval}] Running job #{job.id}\e[0m"
    begin
      block.call
    rescue
      Houston.report_exception($!)
    ensure
      ActiveRecord::Base.clear_active_connections!
    end
  end
end

if defined?(PhusionPassenger)
  PhusionPassenger.on_event(:starting_worker_process) do |forked|
    if forked
      Rails.logger.warn "\e[91mWe're in smart spawning mode\e[0m"
    else
      Rails.logger.warn "\e[92mWe're in direct spawning mode\e[0m"
    end
  end
end
