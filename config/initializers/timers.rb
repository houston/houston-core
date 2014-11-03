# Adapted from https://github.com/jmettraux/rufus-scheduler/issues/10#issuecomment-833423

if Rails.const_defined? :Console
  puts "\e[94mSkipping timers since we're in Rails Console\e[0m"
else
  
  FileUtils.mkdir_p Rails.root.join("tmp/pids")
  pidfile = Rails.root.join("tmp/pids/scheduler").to_s
  
  def execute_scheduler
    # lockfile = Rails.root.join(".rufus-scheduler.lock").to_s
    # $scheduler = Rufus::Scheduler.new(lockfile: lockfile)
    $scheduler = Rufus::Scheduler.new
    raise "Rufus::Scheduler could not be started!" unless $scheduler.up?
    
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
    
  if defined?(PhusionPassenger)
    
    # In its Smart spawning mode, Passenger boots Houston in a
    # "preloader" process and then forks children of that process
    # serve requests.
    #
    # It _should_ be the case that Passenger will never restart
    # the Preloader process when PassengerMaxPreloaderIdleTime
    # is set to 0.
    # https://www.phusionpassenger.com/documentation/Users%20guide%20Apache.html#PassengerMaxPreloaderIdleTime
    #
    # Just in case, the following is set up:
    
    PhusionPassenger.on_event(:starting_worker_process) do |forked|
      # If `forked` is true, then we're in Smart spawning mode which
      # means that it is possible for the preloader process to have died
      # and for no processes to be running the Scheduler thread.
      #
      # If `pidfile` doesn't exist, we'll assume the worst, run the
      # scheduler, and record our PID into the file.
      if forked && !FileTest.exists?(pidfile)
        Rails.logger.info "\e[34m[boot] Starting scheduler on process #{$$}\e[0m"
        File.open(pidfile, "w") { |f| f.write($$) }
        execute_scheduler
      end
    end
    
    PhusionPassenger.on_event(:stopping_worker_process) do
      # If the process begin shut down is also the one that is
      # running the Scheduler thread, we'll release the lock
      # by deleting `pidfile`.
      if FileTest.exists?(pidfile) && File.read(pidfile).to_i == $$
        Rails.logger.info "\e[34m[shutdown] Stopping scheduler on process #{$$}\e[0m"
        File.delete(pidfile)
      end
    end
    
  else
    
    # Assume this is a single-threaded web server
    execute_scheduler
    
  end
end
