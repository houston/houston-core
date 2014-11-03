# Adapted from https://github.com/jmettraux/rufus-scheduler/issues/10#issuecomment-833423

if Rails.const_defined? :Console
  puts "\e[94mSkipping timers since we're in Rails Console\e[0m"
else
  
  lockfile = Rails.root.join(".rufus-scheduler.lock").to_s
  $scheduler = Rufus::Scheduler.new(lockfile: lockfile)
  if $scheduler.up?
    Rails.logger.info "\e[34m[scheduler:boot] Starting scheduler on process #{$$}\e[0m"
    Houston.observer.fire "scheduler:boot"
    
    at_exit do
      Rails.logger.warn "\e[34m[scheduler:shutdown] Stopping scheduler on process #{$$}\e[0m"
      Houston.observer.fire "scheduler:shutdown"
    end
    
    Houston.config.timers.each do |(interval, name, options, block)|
      $scheduler.every(interval, options.merge(tag: name)) do |job|
        Rails.logger.info "\e[34m[#{job.tags.first}/#{job.original}] Running job\e[0m"
        begin
          block.call
        rescue
          Rails.logger.error "\e[31m[#{job.tags.first}/#{job.original}] \e[1m#{$!.message}\e[0m"
          Houston.report_exception($!, job_name: job.tags.first, job_id: job.id) rescue nil
        ensure
          ActiveRecord::Base.clear_active_connections!
        end
      end
    end
  end
  
end
