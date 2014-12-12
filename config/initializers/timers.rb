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
    
    def exceptions_wrapping(error_class)
      m = Module.new
      (class << m; self; end).instance_eval do
        define_method(:===) do |err|
          err.respond_to?(:original_exception) && error_class === err.original_exception
        end
      end
      m
    end
    
    Houston.config.timers.each do |(type, param, name, options, block)|
      wrapped_block = Proc.new do |job|
        Rails.logger.info "\e[34m[#{job.tags.first}/#{job.original}] Running job\e[0m"
        begin
          block.call
        rescue SocketError,
               Errno::ECONNREFUSED,
               Errno::ETIMEDOUT,
               Faraday::Error::ConnectionFailed,
               Idioms::HTTP::ServerError,
               Rugged::NetworkError,
               Unfuddle::ConnectionError,
               exceptions_wrapping(PG::ConnectionBad)
          Rails.logger.error "\e[31m[#{job.tags.first}/#{job.original}] #{$!.class}: #{$!.message} [ignored]\e[0m"
        rescue
          Rails.logger.error "\e[31m[#{job.tags.first}/#{job.original}] \e[1m#{$!.message}\e[0m"
          Houston.report_exception($!, parameters: {job_name: job.tags.first, job_id: job.id})
        ensure
          ActiveRecord::Base.clear_active_connections!
        end
      end
      
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
