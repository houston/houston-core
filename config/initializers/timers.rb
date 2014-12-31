# Adapted from https://github.com/jmettraux/rufus-scheduler/issues/10#issuecomment-833423

if !Houston.server?
  puts "\e[94mSkipping timers since we're not running as a server\e[0m"
  Rails.logger.info "\e[94mSkipping timers since we're not running as a server\e[0m"
else
  
  lockfile = Rails.root.join(".rufus-scheduler.lock").to_s.freeze
  pidfile = Rails.root.join("tmp/pids/scheduler").to_s.freeze
  
  $scheduler = Rufus::Scheduler.new(lockfile: lockfile)
  if $scheduler.up?
    Rails.logger.info "\e[34m[scheduler:boot] Starting scheduler on process #{$$}\e[0m"
    FileUtils.mkdir_p Rails.root.join("tmp/pids")
    File.open(pidfile, "w") { |f| f.write($$) }
    Houston.observer.fire "scheduler:boot"
    
    at_exit do
      if !FileTest.exists?(pidfile) || File.read(pidfile).to_i == $$
        Rails.logger.warn "\e[34m[scheduler:shutdown] Stopping scheduler on process #{$$}\e[0m"
        File.delete(pidfile)
        Houston.observer.fire "scheduler:shutdown"
      end
    end
    
    Houston.config.timers.each do |(type, param, name, options, block)|
      wrapped_block = Houston.jobs.method(:run_job)
      
      case type
      when :cron
        cronline = Whenever::Output::Cron.new(options.fetch(:every, :day), nil, param)
        $scheduler.cron cronline.time_in_cron_syntax, options.merge(tag: name), &wrapped_block
      
      when :every
        $scheduler.every param, options.merge(tag: name), &wrapped_block
      
      else
        raise NotImplementedError, "A #{type.inspect} timer is not implemented"
      end
    end
  end
  
end
