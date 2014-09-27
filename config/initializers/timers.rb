if Rails.const_defined? :Console
  puts "\e[94mSkipping timers since we're in Rails Console\e[0m"
else
  scheduler = Rufus::Scheduler.singleton
  
  Houston.config.timers.each do |(interval, name, options, block)|
    scheduler.every(interval, options.merge(tag: name)) do |job|
      Rails.logger.debug "\e[34m[#{job.tags.first}/#{job.original}] Running job\e[0m"
      begin
        block.call
      rescue
        Rails.logger.warn "\e[31m[#{job.tags.first}/#{job.original}] \e[1m#{$!.message}\e[0m"
        Houston.report_exception($!, job_name: job.tags.first, job_id: job.id) rescue nil
      ensure
        ActiveRecord::Base.clear_active_connections!
      end
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
